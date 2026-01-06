variable "CATALOG_DEFAULT_REGION" {
  description = "The default region for the catalog service."
  type        = string
  default     = "us-east-1"
}

variable "catalog_ssh_key_pair_name" {
  description = "Name of the EC2 key pair for bastion host SSH access"
  type        = string
  default     = "catalog_aws_key_pair"
}

variable "catalog_ssh_key_pair_value" {
  description = "Name of the EC2 key pair for bastion host SSH access"
  type        = string
  # No default - must be provided via terraform.tfvars or environment variable
}

variable "catalog_allowed_ip_cidrs" {
  description = "List of CIDR blocks allowed to access bastion and EKS API (e.g., ['203.0.113.0/24'])"
  type        = list(string)
  default     = []
}