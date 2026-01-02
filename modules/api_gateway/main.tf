locals {
  api_gateway_tags = {"origin": "tc-micro-service-4/modules/api_gateway/main.tf"}
}


#data "http" "open_api_spec" {
#  url = "${data.aws_lb.app_nlb.dns_name}/openapi.json"
#}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.service}-proxy-api"
#  body = data.http.open_api_spec.response_body
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

resource "aws_ssm_parameter" "api_gateway_url" {
  name        = "/ordering-system/${var.service}/apigateway/url"
  description = "API Gateway URL for ${var.service} service"
  type        = "String"
  value       = aws_api_gateway_stage.api_stage.invoke_url
}

resource "aws_lambda_permission" "apigw_authorizer_invoke" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer-${var.service}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/authorizers/*"
}

resource "aws_api_gateway_vpc_link" "catalog" {
  name        = "catalog-vpc-link-${var.service}"
  target_arns = [var.load_balancer_arn]

  tags = local.api_gateway_tags
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.catalog.id
  uri                     = "http://${var.eks_load_balancer_dns_name}/{proxy}"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

}