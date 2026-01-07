output "rest_api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "proxy_id" {
  value = aws_api_gateway_resource.proxy.id
}

output "proxy_http_method" {
  value = aws_api_gateway_method.proxy.http_method
}

output "invoke_url" {
  value       = aws_api_gateway_stage.api_stage.invoke_url
  description = "Invoke URL for the API Gateway stage"
  # Note: aws_api_gateway_stage.invoke_url is only populated in newer provider versions; callers can also construct URL from rest_api id and stage.
}
