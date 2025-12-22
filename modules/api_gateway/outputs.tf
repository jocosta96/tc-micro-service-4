output "http_api_id" {
  description = "ID of the created HTTP API."
  value       = aws_apigatewayv2_api.http_api.id
}

output "http_api_execution_arn" {
  description = "Execution ARN of the HTTP API."
  value       = aws_apigatewayv2_api.http_api.execution_arn
}

output "http_api_invoke_url" {
  description = "Base invoke URL of the HTTP API default stage."
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "lambda_authorizer_arn" {
  description = "ARN of the Lambda authorizer function."
  value       = aws_lambda_function.authorizer.arn
}


