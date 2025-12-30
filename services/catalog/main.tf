terraform {
  backend "s3" {
    bucket = "tc-ordering-state-bucket"
    key    = "catalog-microservice.tfstate"
    region = "us-east-1"
  }
}


module "catalog_network" {
  source = "../../modules/network"

  DEFAULT_REGION     = var.DEFAULT_REGION
  AVAILABILITY_ZONES = ["us-east-1a", "us-east-1b", "us-east-1c"]
  VPC_CIDR_BLOCK     = "10.0.0.0/16"
  subnet_cidr_block  = "10.0.1.0/24"
  SUBNET_COUNT       = 2
  service            = var.service
}

module "catalog_bastion" {
  source = "../../modules/bastion"

  service           = var.service
  vpc_id            = module.catalog_network.service_vpc_id
  subnet_ids        = module.catalog_network.service_subnet_ids
  allowed_ip_cidrs  = var.allowed_ip_cidrs
  key_pair_name     = var.ssh_key_pair_name
  instance_type     = "t3.micro"
  DEFAULT_REGION    = var.DEFAULT_REGION
}

module "catalog_database" {
  source              = "../../modules/database"
  service             = var.service
  DEFAULT_REGION      = var.DEFAULT_REGION
  VPC_ID              = module.catalog_network.service_vpc_id
  allowed_cidr_blocks = [module.catalog_network.service_vpc_cidr_block]
  allowed_security_groups = [
    module.catalog_eks.eks_node_security_group_id,
    module.catalog_eks.eks_security_group_id,
    module.catalog_bastion.security_group_id,
  ]
  subnet_group_name = module.catalog_network.service_data_subnet_group_name
  allow_public_access = false
  key_pair_name     = var.ssh_key_pair_name

  depends_on = [module.catalog_bastion]
}


module "catalog_eks" {
  source = "../../modules/eks"

  service        = var.service
  VPC_CIDR_BLOCK = module.catalog_network.service_vpc_cidr_block
  allow_public_access = false
  VPC_ID              = module.catalog_network.service_vpc_id
  SUBNET_IDS          = module.catalog_network.service_subnet_ids
  NODE_INSTANCE_TYPE  = "t3.small"
  allowed_ip_cidrs    = var.allowed_ip_cidrs
  SCALING_CONFIG = {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
}

module "catalog_api_gateway" {
  source = "../../modules/api_gateway"

  service = var.service
  region  = var.DEFAULT_REGION
  load_balancer_arn  = module.catalog_eks.eks_load_balancer_arn
  eks_load_balancer_dns_name = module.catalog_eks.eks_load_balancer_dns_name
  depends_on = [
    module.catalog_k8s
  ]
}


module "catalog_k8s" {
  source = "../../modules/k8s"

  service                = var.service
  DEFAULT_REGION         = var.DEFAULT_REGION
  cluster_name           = module.catalog_eks.name
  node_group_name        = module.catalog_eks.node_group_name
  image_name             = "jocosta96/soat-challenge"
  image_tag              = "latest"
  vpc_id                 = module.catalog_network.service_vpc_id
  vpc_cidr               = module.catalog_network.service_vpc_cidr_block
  node_security_group_id = module.catalog_eks.eks_node_security_group_id
  eks_load_balancer_arn = module.catalog_eks.eks_load_balancer_arn
  depends_on             = [module.catalog_eks]
}

