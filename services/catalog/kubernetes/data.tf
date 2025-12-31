data "aws_eks_cluster" "cluster" {
  name       = "catalog-eks-cluster"
}

data "aws_eks_cluster_auth" "auth" {
  name       = "catalog-eks-cluster"
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "tc-ordering-state-bucket"
    key    = "catalog-microservice.tfstate"
    region = "us-east-1"
  }
}