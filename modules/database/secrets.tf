locals {
  secret_tags = {
    origin="tc-micro-service-4/modules/database/secrets.tf"
  }
}

# Database configuration parameters
resource "aws_ssm_parameter" "shared_database_host" {
  name        = "/ordering-system/${var.service}/database/host"
  description = "Database host endpoint for cross-repository integration"
  type        = "String"
  value       = aws_db_instance.ordering_database.address

  tags = local.secret_tags
}

resource "aws_ssm_parameter" "shared_database_port" {
  name        = "/ordering-system/${var.service}/database/port"
  description = "Database port for cross-repository integration"
  type        = "String"
  value       = tostring(aws_db_instance.ordering_database.port)

  tags = local.secret_tags
}

resource "aws_ssm_parameter" "shared_database_name" {
  name        = "/ordering-system/${var.service}/database/name"
  description = "Database name for cross-repository integration"
  type        = "String"
  value       = aws_db_instance.ordering_database.db_name

  tags = local.secret_tags
}

resource "aws_ssm_parameter" "shared_database_username" {
  name        = "/ordering-system/${var.service}/database/username"
  description = "Database username for cross-repository integration"
  type        = "String"
  value       = aws_db_instance.ordering_database.username

  tags = local.secret_tags
}

resource "aws_ssm_parameter" "shared_database_password" {
  name        = "/ordering-system/${var.service}/database/password"
  description = "Database password for cross-repository integration"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = local.secret_tags
}
