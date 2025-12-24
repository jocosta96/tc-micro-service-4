variable "service" {
  description = "Name of the service using this API gateway (used in resource names)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "integration_type" {
  description = "Integration type for API Gateway integration. Defaults to HTTP_PROXY for simple HTTP hostnames. Use 'HTTP' when pairing with a VPC_LINK."
  type        = string
  default     = "HTTP_PROXY"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "stage"
}
