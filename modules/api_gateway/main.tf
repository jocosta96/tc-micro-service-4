resource "random_password" "valid_token" {
  length  = 16
  special = true
}

resource "aws_ssm_parameter" "valid_token_ssm" {
  name        = "/ordering-system/${var.service}/apigateway/token"
  description = "Valid token for integration"
  type        = "SecureString"
  value       = random_password.valid_token.result
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/scripts/lambda_authorizer.py"
  output_path = "${path.module}/scripts/lambda_authorizer.zip"
}

resource "aws_lambda_function" "authorizer" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "api-authorizer-${var.service}"
  role             = data.aws_iam_role.lambda_role.arn
  handler          = "lambda_authorizer.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TOKEN = random_password.valid_token.result
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.service}-proxy-api"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_authorizer" "lambda_auth" {
  name                             = "${var.service}-lambda-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api.id
  authorizer_uri                   = aws_lambda_function.authorizer.invoke_arn
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "TOKEN"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.lambda_auth.id
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_deployment" "api" {
  depends_on  = [aws_api_gateway_integration.proxy]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
}

resource "aws_lambda_permission" "apigw_authorizer_invoke" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer-${var.service}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/authorizers/*"
}

data "kubernetes_service" "app_loadbalancer_service" {
  metadata {
    name      = "svc-app-lb-${var.service}"
    namespace = "default"
  }
}

# Discover the NLB created by the Kubernetes Service using its hostname
# Add explicit dependency on the Kubernetes service to ensure it exists before lookup
data "aws_lb" "app_nlb" {
  tags = { "kubernetes.io/service-name" = "default/svc-app-lb-${var.service}" }

  depends_on = [data.kubernetes_service.app_loadbalancer_service]
}


resource "null_resource" "wait_for_nlb_active" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = templatefile(
      "${path.module}/scripts/wait_load_balancer.sh",
      {
        app_nlb_arn = data.aws_lb.app_nlb.arn
      }
    )
  }
}

resource "aws_api_gateway_vpc_link" "catalog" {
  name        = "catalog-vpc-link-${var.service}"
  target_arns = [data.aws_lb.app_nlb.arn]

  depends_on = [null_resource.wait_for_nlb_active]
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.catalog.id
  uri                     = "http://${data.aws_lb.app_nlb.dns_name}/{proxy}"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  depends_on = [null_resource.wait_for_nlb_active]
}