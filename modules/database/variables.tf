# Provider variables
variable "DEFAULT_REGION" {
  description = "The default region to use for the AWS provider"
  type        = string
  default     = "us-east-1"
}

# Database configuration variables
variable "DB_INSTANCE_CLASS" {
  description = "The instance class for the RDS database"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage for the RDS database in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "The maximum allocated storage for the RDS database in GB"
  type        = number
  default     = 100
}

variable "db_engine_version" {
  description = "The PostgreSQL engine version"
  type        = string
  default     = "17.7"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "ordering_system"
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  default     = "ordering_admin"
}

variable "db_port" {
  description = "The port for the database"
  type        = number
  default     = 5432
}

variable "BACKUP_RETENTION_PERIOD" {
  description = "The number of days to retain backups"
  type        = number
  default     = 1
}

variable "MULTI_AZ" {
  description = "Whether to enable multi-AZ deployment"
  type        = bool
  default     = false
}

# Network access variables
variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "List of security group IDs allowed to access the database"
  type        = list(string)
}

variable "service" {
  type = string
}

variable "VPC_ID" {
  description = "The ID of the VPC where the database will be deployed"
  type        = string
}

variable "subnet_group_name" {
  description = "The name of the DB subnet group"
  type        = string
}