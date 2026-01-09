terraform {
  backend "s3" {
    bucket       = "tc-microservices-state-bucket"
    key          = "catalog-microservice.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

locals {
  service_name = "catalog"
}

module "catalog_network" {
  source = "../../modules/network"

  DEFAULT_REGION     = var.CATALOG_DEFAULT_REGION
  AVAILABILITY_ZONES = ["us-east-1a", "us-east-1b", "us-east-1c"]
  VPC_CIDR_BLOCK     = "10.0.0.0/16"
  subnet_cidr_block  = "10.0.1.0/24"
  SUBNET_COUNT       = 2
  service            = local.service_name
}

module "catalog_bastion" {
  source = "../../modules/bastion"

  service          = local.service_name
  vpc_id           = module.catalog_network.service_vpc_id
  subnet_ids       = module.catalog_network.service_subnet_ids
  allowed_ip_cidrs = var.catalog_allowed_ip_cidrs
  key_pair_name    = var.catalog_ssh_key_pair_name
  key_pair_value   = var.catalog_ssh_key_pair_value
  instance_type    = "t3.micro"
  DEFAULT_REGION   = var.CATALOG_DEFAULT_REGION
}

module "catalog_database" {
  source              = "../../modules/postgres"
  service             = local.service_name
  DEFAULT_REGION      = var.CATALOG_DEFAULT_REGION
  VPC_ID              = module.catalog_network.service_vpc_id
  allowed_cidr_blocks = [module.catalog_network.service_vpc_cidr_block]
  allowed_security_groups = [
    module.catalog_eks.eks_node_security_group_id,
    module.catalog_eks.eks_security_group_id,
    module.catalog_bastion.security_group_id,
  ]
  subnet_group_name   = module.catalog_network.service_data_subnet_group_name
  allow_public_access = true
}


module "catalog_eks" {
  source = "../../modules/eks"

  service             = local.service_name
  VPC_CIDR_BLOCK      = module.catalog_network.service_vpc_cidr_block
  allow_public_access = false
  VPC_ID              = module.catalog_network.service_vpc_id
  SUBNET_IDS          = module.catalog_network.service_subnet_ids
  NODE_INSTANCE_TYPE  = "t3.small"
  allowed_ip_cidrs    = var.catalog_allowed_ip_cidrs
  SCALING_CONFIG = {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
  key_pair_name             = var.catalog_ssh_key_pair_name
  bastion_security_group_id = module.catalog_bastion.security_group_id
}

module "catalog_api_gateway" {
  source = "../../modules/api_gateway"

  service                    = local.service_name
  region                     = var.CATALOG_DEFAULT_REGION
  load_balancer_arn          = module.catalog_eks.eks_load_balancer_arn
  eks_load_balancer_dns_name = module.catalog_eks.eks_load_balancer_dns_name
}

module "catalog_k8s" {
  source = "../../modules/k8s"

  service                = local.service_name
  DEFAULT_REGION         = var.CATALOG_DEFAULT_REGION
  cluster_name           = module.catalog_eks.name
  node_group_name        = module.catalog_eks.node_group_name
  image_name             = var.catalog_app_image_name
  image_tag              = var.catalog_app_image_tag
  vpc_id                 = module.catalog_network.service_vpc_id
  vpc_cidr               = module.catalog_network.service_vpc_cidr_block
  node_security_group_id = module.catalog_eks.eks_node_security_group_id
  nlb_target_group_arn   = module.catalog_eks.nlb_target_group_arn
  app_command            = file("${path.module}/scripts/app_command.sh")
  depends_on             = [module.catalog_eks]
}