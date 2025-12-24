terraform {
  backend "s3" {
    bucket = "tc-ordering-state-bucket"
    key    = "order-microservice.tfstate"
    region = "us-east-1"
  }
}

module "order_network" {
  source = "../../modules/network"

  DEFAULT_REGION     = var.DEFAULT_REGION
  AVAILABILITY_ZONES = ["us-east-1a", "us-east-1b", "us-east-1c"]
  VPC_CIDR_BLOCK     = "10.10.0.0/16"
  subnet_cidr_block  = "10.10.1.0/24"
  SUBNET_COUNT       = 2
  service            = "order"
}

module "order_database" {
  source              = "../../modules/database"
  service             = "order"
  DEFAULT_REGION      = var.DEFAULT_REGION
  VPC_ID              = module.order_network.service_vpc_id
  allowed_cidr_blocks = [module.order_network.service_vpc_cidr_block]
  # Allow connections from EKS node security group (where pods run), not cluster security group
  allowed_security_groups = [
    module.order_eks.eks_node_security_group_id,
    module.order_eks.eks_security_group_id,
  ]
  subnet_group_name = module.order_network.service_data_subnet_group_name
}

module "order_eks" {
  source = "../../modules/eks"

  service        = "order"
  VPC_CIDR_BLOCK = module.order_network.service_vpc_cidr_block
  # For production-style traffic we keep the EKS API and worker nodes private.
  allow_public_access = false
  VPC_ID              = module.order_network.service_vpc_id
  SUBNET_IDS          = module.order_network.service_subnet_ids
  NODE_AMI_TYPE       = "BOTTLEROCKET_x86_64" #faster than default one
  NODE_INSTANCE_TYPE  = "t3.small"
  SCALING_CONFIG = {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
}

module "order_api_gateway" {
  source = "../../modules/api_gateway"

  service = "order"
  region  = var.DEFAULT_REGION
  depends_on = [
    module.order_eks,
    module.order_k8s
  ]
}


module "order_k8s" {
  source = "../../modules/k8s"

  service                = "order"
  DEFAULT_REGION         = var.DEFAULT_REGION
  cluster_name           = module.order_eks.name
  node_group_name        = module.order_eks.node_group_name
  image_name             = "jocosta96/soat-challenge"
  vpc_id                 = module.order_network.service_vpc_id
  vpc_cidr               = module.order_network.service_vpc_cidr_block
  node_security_group_id = module.order_eks.eks_node_security_group_id
  depends_on             = [module.order_eks]
}

