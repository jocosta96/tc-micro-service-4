variable "service" {
  type    = string
  default = ""
}

variable "allow_public_access" {
  description = "enable public access for development purposes"
  type        = bool
  default     = false
}

# Network variables
variable "VPC_CIDR_BLOCK" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "VPC_ID" {
  description = "The ID of the VPC"
  type        = string
  default     = ""
}

variable "SUBNET_IDS" {
  description = "The IDs of the subnets"
  type        = list(string)
  default     = []
}

variable "DEFAULT_REGION" {
  description = "The default region for the EKS service."
  type        = string
  default     = "us-east-1"
}

variable "K8S_NAMESPACE" {
  type    = string
  default = "default"
}

variable "NODE_INSTANCE_TYPE" {
  type    = string
  default = "t3.medium"
}

variable "NODE_AMI_TYPE" {
  type    = string
  default = "BOTTLEROCKET_x86_64"
}

variable "SCALING_CONFIG" {
  type = object({
    desired_size = number
    max_size     = number
    min_size     = number
  })
  default = {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
}

variable "allowed_ip_cidrs" {
  description = "List of CIDR blocks allowed to access EKS API server"
  type        = list(string)
  default     = []
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.nano"
}

variable "bastion_key_name" {
  description = "Key pair name for bastion host"
  type        = string
  default     = ""
}