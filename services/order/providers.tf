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
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.auth.token
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.auth.token
}

resource "terraform_data" "refresh_kubectl" {
  input = { filename = "~/.kube/config" }
  provisioner "local-exec" {
    command    = "kubectl config delete-context ${local.service_name}"
    on_failure = continue
  }
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.ORDER_DEFAULT_REGION} --name ${module.order_eks.name} --alias ${local.service_name}"
  }
  triggers_replace = timestamp()
}

data "aws_eks_cluster" "cluster" {
  name       = module.order_eks.name
  depends_on = [module.order_eks]
}

data "aws_eks_cluster_auth" "auth" {
  name       = module.order_eks.name
  depends_on = [terraform_data.refresh_kubectl]
}

provider "time" {}