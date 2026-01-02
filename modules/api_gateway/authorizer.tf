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