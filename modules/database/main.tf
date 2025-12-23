locals {
  database_tags = {
    origin = "tc-micro-service-4/modules/database/main.tf"
  }
}

# Generate random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
  # Exclude characters that AWS RDS doesn't allow: / @ " and space
  override_special = "!#$%&*()-_=+[]{}|;:,.<>?"
}

# Create RDS PostgreSQL database
resource "aws_db_instance" "ordering_database" {
  identifier = "${var.service}-postgres"

  # Engine settings
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.DB_INSTANCE_CLASS

  # Storage settings
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database settings
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = var.db_port

  # Network settings
  db_subnet_group_name   = "${var.service}-subnet-group"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false

  # Backup settings
  backup_retention_period = var.BACKUP_RETENTION_PERIOD
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # High availability
  multi_az = var.MULTI_AZ

  # Performance and monitoring
  performance_insights_enabled = false
  monitoring_interval          = 0

  # Deletion protection and cleanup
  deletion_protection      = false
  delete_automated_backups = true
  skip_final_snapshot      = true
  copy_tags_to_snapshot    = true

  # Disable auto minor version upgrades for stability
  auto_minor_version_upgrade = false

  tags = local.database_tags
}
