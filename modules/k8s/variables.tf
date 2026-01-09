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
  type = string
}

variable "image_name" {
  type = string
}

variable "image_tag" {
  type    = string
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

variable "nlb_target_group_arn" {
  type = string
}

variable "app_command" {
  type        = string
  description = "command to run on deployment"
}