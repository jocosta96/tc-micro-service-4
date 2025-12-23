terraform {
  required_version = "1.14.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6.3"
    }
  }
}