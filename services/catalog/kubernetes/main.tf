terraform {
  backend "s3" {
    bucket = "tc-ordering-state-bucket"
    key    = "catalog-kubernetes.tfstate"
    region = "us-east-1"
#    use_lockfile = true
  }
}


module "catalog_k8s" {
  source = "../../../modules/k8s"

  service                         = var.service
  DEFAULT_REGION                  = var.DEFAULT_REGION
  cluster_name                    = data.terraform_remote_state.infra.outputs.cluster_name
  cluster_endpoint                = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_certificate_authority_data = data.terraform_remote_state.infra.outputs.cluster_certificate_authority_data
  image_name                      = "jocosta96/soat-challenge"
  image_tag                       = "latest"
  vpc_id                          = data.terraform_remote_state.infra.outputs.vpc_id
  vpc_cidr                        = data.terraform_remote_state.infra.outputs.vpc_cidr
  node_security_group_id          = data.terraform_remote_state.infra.outputs.node_security_group_id
  eks_load_balancer_arn           = data.terraform_remote_state.infra.outputs.eks_load_balancer_arn
  eks_target_group_arn            = data.terraform_remote_state.infra.outputs.eks_target_group_arn

}

