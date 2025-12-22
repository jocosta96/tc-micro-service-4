terraform {
  backend "s3" {
    bucket = "tc-ordering-state-bucket"
    key    = "catalog-microservice.tfstate"
    region = "us-east-1"
  }
  required_version = "1.14.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
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

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name, "--region", var.DEFAULT_REGION]
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name, "--region", var.DEFAULT_REGION]
  }
}



data "aws_eks_cluster" "cluster" {
  name = "catalog-eks-cluster"
  depends_on = [ module.catalog_eks ]
}

data "aws_eks_cluster_auth" "auth" {
  name = "catalog-eks-cluster"
  depends_on = [ module.catalog_eks ]
}
