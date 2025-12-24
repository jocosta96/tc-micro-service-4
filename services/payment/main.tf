terraform {
  backend "s3" {
    bucket = "tc-paymenting-state-bucket"
    key    = "payment-microservice.tfstate"
    region = "us-east-1"
  }
}

module "payment_network" {
  source = "../../modules/network"

  DEFAULT_REGION     = var.DEFAULT_REGION
  AVAILABILITY_ZONES = ["us-east-1a", "us-east-1b", "us-east-1c"]
  VPC_CIDR_BLOCK     = "10.20.0.0/16"
  subnet_cidr_block  = "10.20.1.0/24"
  SUBNET_COUNT       = 2
  service            = "payment"
}

module "payment_database" {
  source              = "../../modules/database"
  service             = "payment"
  DEFAULT_REGION      = var.DEFAULT_REGION
  VPC_ID              = module.payment_network.service_vpc_id
  allowed_cidr_blocks = [module.payment_network.service_vpc_cidr_block]
  # Allow connections from EKS node security group (where pods run), not cluster security group
  allowed_security_groups = [
    module.payment_eks.eks_node_security_group_id,
    module.payment_eks.eks_security_group_id,
  ]
  subnet_group_name = module.payment_network.service_data_subnet_group_name
}

module "payment_eks" {
  source = "../../modules/eks"

  service        = "payment"
  VPC_CIDR_BLOCK = module.payment_network.service_vpc_cidr_block
  # For production-style traffic we keep the EKS API and worker nodes private.
  allow_public_access = false
  VPC_ID              = module.payment_network.service_vpc_id
  SUBNET_IDS          = module.payment_network.service_subnet_ids
  NODE_AMI_TYPE       = "BOTTLEROCKET_x86_64" #faster than default one
  NODE_INSTANCE_TYPE  = "t3.small"
  SCALING_CONFIG = {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
}

module "payment_api_gateway" {
  source = "../../modules/api_gateway"

  service = "payment"
  region  = var.DEFAULT_REGION
  depends_on = [
    module.payment_eks,
    module.payment_k8s
  ]
}


module "payment_k8s" {
  source = "../../modules/k8s"

  service                = "payment"
  DEFAULT_REGION         = var.DEFAULT_REGION
  cluster_name           = module.payment_eks.name
  node_group_name        = module.payment_eks.node_group_name
  image_name             = "jocosta96/soat-challenge"
  vpc_id                 = module.payment_network.service_vpc_id
  vpc_cidr               = module.payment_network.service_vpc_cidr_block
  node_security_group_id = module.payment_eks.eks_node_security_group_id
  depends_on             = [module.payment_eks]
}

