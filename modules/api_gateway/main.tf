locals {
  api_tags = merge(
    {
      service = var.service
      origin  = "tc-micro-service-4/modules/api_gateway/main.tf"
    },
    var.tags,
  )
}

# =========================
# Lambda authorizer
# =========================

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_authorizer.py"
  output_path = "${path.module}/lambda_authorizer.zip"
}

resource "aws_lambda_function" "authorizer" {
  function_name = "${var.service}-authorizer"
  role          = data.aws_iam_role.lab_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.12"
  handler = "lambda_authorizer.lambda_handler"

  environment {
    variables = {
      TOKEN = var.authorizer_token
    }
  }

  tags = local.api_tags
}

# =========================
# HTTP API Gateway + Lambda authorizer
# =========================

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.service}-http-api"
  protocol_type = "HTTP"

  tags = local.api_tags
}

resource "aws_apigatewayv2_vpc_link" "this" {
  count = length(var.vpc_link_subnet_ids) > 0 ? 1 : 0

  name               = "${var.service}-vpc-link"
  subnet_ids         = var.vpc_link_subnet_ids
  security_group_ids = var.vpc_link_security_group_ids

  tags = local.api_tags
}

resource "aws_apigatewayv2_authorizer" "lambda_authorizer" {
  api_id           = aws_apigatewayv2_api.http_api.id
  authorizer_type  = "REQUEST"
  name             = "${var.service}-lambda-authorizer"
  authorizer_uri   = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.authorizer.arn}/invocations"
  identity_sources = ["$request.header.Authorization"]

  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

resource "aws_lambda_permission" "allow_apigw_invoke_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "http_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "HTTP_PROXY"

  integration_uri    = var.integration_uri
  integration_method = "ANY"

  connection_type = length(var.vpc_link_subnet_ids) > 0 ? "VPC_LINK" : "INTERNET"
  connection_id   = length(var.vpc_link_subnet_ids) > 0 ? aws_apigatewayv2_vpc_link.this[0].id : null
}

resource "aws_apigatewayv2_route" "proxy_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"

  target           = "integrations/${aws_apigatewayv2_integration.http_integration.id}"
  authorizer_id    = aws_apigatewayv2_authorizer.lambda_authorizer.id
  authorization_type = "CUSTOM"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  tags = local.api_tags
}


