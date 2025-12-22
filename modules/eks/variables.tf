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
  type = string
  default = "default"
}
