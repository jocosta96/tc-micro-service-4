# Output para usar em outros módulos
output "payment_table_name" {
  description = "Nome da tabela DynamoDB de pagamentos"
  value       = aws_dynamodb_table.payment_transactions.name
}

output "payment_table_arn" {
  description = "ARN da tabela DynamoDB de pagamentos"
  value       = aws_dynamodb_table.payment_transactions.arn
}

output "payment_table_stream_arn" {
  description = "ARN do stream da tabela (para triggers Lambda)"
  value       = aws_dynamodb_table.payment_transactions.stream_arn
}