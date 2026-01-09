# DynamoDB Table for Payment Service
# Tabela de transações de pagamento com índices para busca por order_id e provider_tx_id

resource "aws_dynamodb_table" "payment_transactions" {
  name         = var.payment_table_name
  billing_mode = "PAY_PER_REQUEST" # On-demand billing (sem provisionamento)
  hash_key     = "id"

  # Partition Key (Primary Key)
  attribute {
    name = "id"
    type = "S" # String - UUID da transação
  }

  # Attribute para GSI order_id-index
  attribute {
    name = "order_id"
    type = "N" # Number - ID do pedido
  }

  # Attribute para GSI provider_tx_id-index
  attribute {
    name = "provider_tx_id"
    type = "S" # String - ID do Mercado Pago
  }

  # Global Secondary Index 1: Buscar por order_id
  global_secondary_index {
    name            = "order_id-index"
    hash_key        = "order_id"
    projection_type = "ALL"
  }

  # Global Secondary Index 2: Buscar por provider_tx_id (ID do Mercado Pago)
  global_secondary_index {
    name            = "provider_tx_id-index"
    hash_key        = "provider_tx_id"
    projection_type = "ALL"
  }

  # TTL para expiração automática (opcional - descomente se quiser)
  # ttl {
  #   attribute_name = "ttl"
  #   enabled        = true
  # }

  # Point-in-time recovery (backup contínuo)
  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Tags para organização
  tags = {
    Name = var.payment_table_name
  }
}
