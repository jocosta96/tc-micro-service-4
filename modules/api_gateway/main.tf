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
  source_file = "${path.module}/lambda_authorizer.py"
  output_path = "${path.module}/lambda_authorizer.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "api-authorizer-role-${var.service}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_logs" {
  name   = "api-authorizer-logs-${var.service}"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "authorizer" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "api-authorizer-${var.service}"
  role             = aws_iam_role.lambda_role.arn
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

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${data.kubernetes_service.app_loadbalancer_service.status[0].load_balancer[0].ingress[0].hostname}/{proxy}"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}