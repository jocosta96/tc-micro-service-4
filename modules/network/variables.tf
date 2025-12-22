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