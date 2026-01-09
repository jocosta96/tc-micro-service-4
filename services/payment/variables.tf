variable "PAYMENT_DEFAULT_REGION" {
  description = "The default region for the payment service."
  type        = string
  default     = "us-east-1"
}

variable "payment_ssh_key_pair_name" {
  description = "Name of the EC2 key pair for bastion host SSH access"
  type        = string
  default     = "payment_aws_key_pair"
}

variable "payment_ssh_key_pair_value" {
  description = "Name of the EC2 key pair for bastion host SSH access"
  type        = string
  sensitive   = true
  # No default - must be provided via terraform.tfvars or environment variable
}

variable "payment_app_image_name" {
  type = string
}

variable "payment_app_image_tag" {
  type = string
}

variable "payment_allowed_ip_cidrs" {
  description = "List of CIDR blocks allowed to access bastion and EKS API (e.g., ['203.0.113.0/24'])"
  type        = list(string)
  default     = []
}

variable "aws_access_key_id" {
  sensitive = true
  type      = string
}

variable "aws_secret_access_key" {
  sensitive = true
  type      = string
}

variable "aws_session_token" {
  sensitive = true
  type      = string
}

# Store AWS credentials in SSM
resource "aws_ssm_parameter" "aws_access_key_id" {
  name  = "/ordering-system/${local.service_name}/aws/access_key_id"
  type  = "SecureString"
  value = var.aws_access_key_id
}

resource "aws_ssm_parameter" "aws_secret_access_key" {
  name  = "/ordering-system/${local.service_name}/aws/secret_access_key"
  type  = "SecureString"
  value = var.aws_secret_access_key
}

resource "aws_ssm_parameter" "aws_session_token" {
  name  = "/ordering-system/${local.service_name}/aws/session_token"
  type  = "SecureString"
  value = var.aws_session_token
}
