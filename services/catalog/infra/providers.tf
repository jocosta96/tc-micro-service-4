terraform {
  required_version = ">= 1.12.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }

}

provider "aws" {
  region = "us-east-1"
}

provider "time" {}