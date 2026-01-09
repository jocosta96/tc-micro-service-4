variable "ORDER_DEFAULT_REGION" {
  description = "The default region for the order service."
  type        = string
  default     = "us-east-1"
}

variable "order_ssh_key_pair_name" {
  description = "Name of the EC2 key pair for bastion host SSH access"
  type        = string
  default     = "order_aws_key_pair"
}

variable "order_ssh_key_pair_value" {
  description = "Name of the EC2 key pair for bastion host SSH access"
  type        = string
  sensitive   = true
  # No default - must be provided via terraform.tfvars or environment variable
}

variable "order_app_image_name" {
  type = string
}

variable "order_app_image_tag" {
  type = string
}

variable "order_allowed_ip_cidrs" {
  description = "List of CIDR blocks allowed to access bastion and EKS API (e.g., ['203.0.113.0/24'])"
  type        = list(string)
  default     = []
}