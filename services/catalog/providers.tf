terraform {
  required_version = ">= 1.12.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    #    kubernetes = {
    #      source  = "hashicorp/kubernetes"
    #      version = "2.36.0"
    #    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
  }

}

provider "helm" {
  kubernetes = {
    config_path = terraform_data.refresh_kubectl.input.filename
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  load_config_file       = true
  token                  = data.aws_eks_cluster_auth.auth.token
}

#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.cluster.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#  token = data.aws_eks_cluster_auth.auth.token
#}


resource "terraform_data" "refresh_kubectl" {
  input = { filename = "~/.kube/config" }
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.CATALOG_DEFAULT_REGION} --name ${module.catalog_eks.name} --alias catalog-cluster"
  }
  triggers_replace = timestamp()
}

data "aws_eks_cluster" "cluster" {
  name       = module.catalog_eks.name
  depends_on = [module.catalog_eks]
}

data "aws_eks_cluster_auth" "auth" {
  name       = "catalog-eks-cluster"
  depends_on = [terraform_data.refresh_kubectl]
}


provider "time" {}