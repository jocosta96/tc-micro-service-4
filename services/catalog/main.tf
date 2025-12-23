module "catalog_network" {
  source = "../../modules/network"

  DEFAULT_REGION     = var.DEFAULT_REGION
  AVAILABILITY_ZONES = ["us-east-1a", "us-east-1b", "us-east-1c"]
  VPC_CIDR_BLOCK     = "10.0.0.0/16"
  subnet_cidr_block  = "10.0.1.0/24"
  SUBNET_COUNT       = 2
  service            = "catalog"
}

module "catalog_database" {
  source = "../../modules/database"
  service        = "catalog"
  DEFAULT_REGION = var.DEFAULT_REGION
  VPC_ID         = module.catalog_network.service_vpc_id
  allowed_cidr_blocks = module.catalog_network.service_private_subnet_ids
  allowed_security_groups = [module.catalog_eks.eks_security_group_id]
  subnet_group_name = module.catalog_network.service_data_subnet_group_name
}

module "catalog_eks" {
  source = "../../modules/eks"

  service             = "catalog"
  VPC_CIDR_BLOCK      = module.catalog_network.service_vpc_cidr_block
  # For production-style traffic we keep the EKS API and worker nodes private.
  allow_public_access = false
  VPC_ID              = module.catalog_network.service_vpc_id
  SUBNET_IDS          = module.catalog_network.service_subnet_ids
  NODE_AMI_TYPE       = "BOTTLEROCKET_x86_64" #faster than default one
  NODE_INSTANCE_TYPE  = "t3.small"
  SCALING_CONFIG = {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
}

module "catalog_api_gateway" {
  source = "../../modules/api_gateway"

  service = "catalog"
  region  = var.DEFAULT_REGION
  depends_on = [
    module.catalog_eks,
    module.catalog_k8s,
    module.catalog_database # IS NOT A REAL DEPENDENCY BUT TO GIVE LOAD BALANCER TIME TO GET READY
  ]
}


module "catalog_k8s" {
  source = "../../modules/k8s"

  service        = "catalog"
  DEFAULT_REGION = var.DEFAULT_REGION
  cluster_name   = module.catalog_eks.name
  node_group_name = module.catalog_eks.node_group_name

}

