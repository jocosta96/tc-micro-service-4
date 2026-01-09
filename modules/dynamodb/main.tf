# DynamoDB Table for Payment Service
# Tabela de transações de pagamento com índices para busca por order_id e provider_tx_id


data "aws_caller_identity" "current" {}

resource "aws_kms_key" "service" {
  description             =  var.service_name
  enable_key_rotation     = true
  deletion_window_in_days = 20
}

resource "aws_kms_key_policy" "service" {
  key_id = aws_kms_key.service.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-${var.service_name}"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}


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
    kms_key_arn = aws_kms_key.service.arn
  }

  # Tags para organização
  tags = {
    Name = var.payment_table_name
  }
}
