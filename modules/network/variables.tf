variable "DEFAULT_REGION" {
  description = "The default region for the catalog service."
  type        = string
  default     = ""
}

variable "AVAILABILITY_ZONES" {
  description = "The availability zones to use for the subnet"
  type        = list(string)
  default     = []
}

# Network variables
variable "VPC_CIDR_BLOCK" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = ""
}

variable "SUBNET_COUNT" {
  description = "The number of subnets to create (must be <= length of availability_zones)"
  type        = number
  default     = 2
  validation {
    condition     = var.SUBNET_COUNT <= length(var.AVAILABILITY_ZONES)
    error_message = "subnet_count must be less than or equal to the number of availability zones"
  }
}

variable "PUBLIC_SUBNET_CIDR_BLOCK_BASE" {
  description = "Base CIDR block for public subnets (e.g., 10.0.32.0/21 for AZ0, 10.0.40.0/21 for AZ1)"
  type        = number
  default     = 32
}

variable "PRIVATE_SUBNET_CIDR_BLOCK_BASE" {
  description = "Base CIDR block for private subnets (e.g., 10.0.48.0/21 for AZ0, 10.0.56.0/21 for AZ1)"
  type        = number
  default     = 48
}