variable "DEFAULT_REGION" {
  type    = string
  default = "us-east-1"
}

variable "service" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "node_group_name" {
  type    = string
  default = null
}

variable "image_name" {
  type = string
}

variable "image_tag" {
  type = string
  default = "latest"
}
variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "node_security_group_id" {
  type = string
}

variable "eks_load_balancer_arn" {
  type = string
}

variable "eks_target_group_arn" {
  type = string
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "Base64 encoded certificate data for EKS cluster"
  sensitive   = true
}
