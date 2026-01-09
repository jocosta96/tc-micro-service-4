variable "payment_table_name" {
  description = "Nome da tabela DynamoDB para transações de pagamento"
  type        = string
  default     = "payment-transactions"
}

variable "enable_pitr" {
  description = "Habilitar Point-in-Time Recovery (backup contínuo)"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "service_name" {
  type = string
}