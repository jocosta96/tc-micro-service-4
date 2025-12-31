variable "DEFAULT_REGION" {
  description = "The default region for the catalog service."
  type        = string
  default     = "us-east-1"
}

variable "service" {
  type = string
  default = "catalog"
}
