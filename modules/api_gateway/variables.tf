variable "service" {
  description = "Logical name of the microservice (used for naming API Gateway and Lambda resources)."
  type        = string
}

variable "region" {
  description = "AWS region where API Gateway and Lambda will be created."
  type        = string
}

variable "authorizer_token" {
  description = "Shared static token that the Lambda authorizer will validate against."
  type        = string
}

variable "integration_uri" {
  description = "The integration URI that API Gateway will invoke. For VPC_LINK integrations this should typically be an NLB listener ARN."
  type        = string
}

variable "vpc_link_subnet_ids" {
  description = "Private subnet IDs used to create the API Gateway VPC Link to the NLB that fronts the EKS service."
  type        = list(string)
  default     = []
}

variable "vpc_link_security_group_ids" {
  description = "Security groups attached to the VPC Link ENIs (if required)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Optional tags to apply to created resources."
  type        = map(string)
  default     = {}
}


