terraform {
  backend "s3" {
    bucket       = "tc-microservices-state-bucket"
    key          = "payment-microservice.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

locals {
  service_name = "payment"
}

module "payment_network" {
  source = "../../modules/network"

  DEFAULT_REGION     = var.PAYMENT_DEFAULT_REGION
  AVAILABILITY_ZONES = ["us-east-1a", "us-east-1b", "us-east-1c"]
  VPC_CIDR_BLOCK     = "10.20.0.0/16"
  subnet_cidr_block  = "10.20.1.0/24"
  SUBNET_COUNT       = 2
  service            = local.service_name
}

module "payment_bastion" {
  source = "../../modules/bastion"

  service          = local.service_name
  vpc_id           = module.payment_network.service_vpc_id
  subnet_ids       = module.payment_network.service_subnet_ids
  allowed_ip_cidrs = var.payment_allowed_ip_cidrs
  key_pair_name    = var.payment_ssh_key_pair_name
  key_pair_value   = var.payment_ssh_key_pair_value
  instance_type    = "t3.micro"
  DEFAULT_REGION   = var.PAYMENT_DEFAULT_REGION
}

module "payment_dynamodb" {
  source             = "../../modules/dynamodb"
  payment_table_name = "payment-transactions"
  enable_pitr        = true
  aws_region         = var.PAYMENT_DEFAULT_REGION
  service_name       = local.service_name
}


module "payment_eks" {
  source = "../../modules/eks"

  service             = local.service_name
  VPC_CIDR_BLOCK      = module.payment_network.service_vpc_cidr_block
  allow_public_access = false
  VPC_ID              = module.payment_network.service_vpc_id
  SUBNET_IDS          = module.payment_network.service_subnet_ids
  NODE_INSTANCE_TYPE  = "t3.small"
  allowed_ip_cidrs    = var.payment_allowed_ip_cidrs
  SCALING_CONFIG = {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
  key_pair_name             = var.payment_ssh_key_pair_name
  bastion_security_group_id = module.payment_bastion.security_group_id
}

module "payment_api_gateway" {
  source = "../../modules/api_gateway"

  service                    = local.service_name
  region                     = var.PAYMENT_DEFAULT_REGION
  load_balancer_arn          = module.payment_eks.eks_load_balancer_arn
  eks_load_balancer_dns_name = module.payment_eks.eks_load_balancer_dns_name
}

module "payment_k8s" {
  source = "../../modules/k8s"

  service                = local.service_name
  DEFAULT_REGION         = var.PAYMENT_DEFAULT_REGION
  cluster_name           = module.payment_eks.name
  node_group_name        = module.payment_eks.node_group_name
  image_name             = var.payment_app_image_name
  image_tag              = var.payment_app_image_tag
  vpc_id                 = module.payment_network.service_vpc_id
  vpc_cidr               = module.payment_network.service_vpc_cidr_block
  node_security_group_id = module.payment_eks.eks_node_security_group_id
  nlb_target_group_arn   = module.payment_eks.nlb_target_group_arn
  app_command            = file("${path.module}/scripts/app_command.sh")
  depends_on             = [module.payment_eks]
}