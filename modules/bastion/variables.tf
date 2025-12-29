variable "service" {
  description = "Service name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where bastion will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for bastion host"
  type        = list(string)
}

variable "allowed_ip_cidrs" {
  description = "List of CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = []
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "database_endpoint" {
  description = "Database endpoint address for SSH tunnel configuration"
  type        = string
}

variable "database_port" {
  description = "Database port for SSH tunnel configuration"
  type        = number
  default     = 5432
}

variable "ssm_path_prefix" {
  description = "SSM Parameter Store path prefix for database credentials"
  type        = string
}

variable "DEFAULT_REGION" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

