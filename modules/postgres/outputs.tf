output "database_endpoint" {
  description = "RDS database endpoint address"
  value       = aws_db_instance.ordering_database.address
}

output "database_port" {
  description = "RDS database port"
  value       = aws_db_instance.ordering_database.port
}

output "database_name" {
  description = "RDS database name"
  value       = aws_db_instance.ordering_database.db_name
}

output "ssm_path_prefix" {
  description = "SSM Parameter Store path prefix for database credentials"
  value       = "/ordering-system/${var.service}/database"
}

output "database_security_group_id" {
  description = "Security group ID of the database"
  value       = aws_security_group.db_sg.id
}
