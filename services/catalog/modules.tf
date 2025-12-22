module "catalog_network" {
  source = "../../modules/network"

  DEFAULT_REGION        = var.DEFAULT_REGION
  AVAILABILITY_ZONES    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  VPC_CIDR_BLOCK        = "10.0.0.0/16"
  subnet_cidr_block     = "10.0.1.0/24"
  SUBNET_COUNT          = 2
}

module "catalog_eks" {
  source = "../../modules/eks"

  service               = "catalog"
  VPC_CIDR_BLOCK        = module.catalog_network.service_vpc_cidr_block
  allow_public_access   = true
  VPC_ID                = module.catalog_network.service_vpc_id
  SUBNET_IDS            = module.catalog_network.service_subnet_ids
}
