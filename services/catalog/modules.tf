module "catalog_network" {
  source = "../../modules/network"

  DEFAULT_REGION     = var.DEFAULT_REGION
  AVAILABILITY_ZONES = ["us-east-1a", "us-east-1b", "us-east-1c"]
  VPC_CIDR_BLOCK     = "10.0.0.0/16"
  subnet_cidr_block  = "10.0.1.0/24"
  SUBNET_COUNT       = 2
}

module "catalog_eks" {
  source = "../../modules/eks"

  service             = "catalog"
  VPC_CIDR_BLOCK      = module.catalog_network.service_vpc_cidr_block
  # For production-style traffic we keep the EKS API and worker nodes private.
  allow_public_access = false
  VPC_ID              = module.catalog_network.service_vpc_id
  SUBNET_IDS          = module.catalog_network.service_subnet_ids
}

# API Gateway + Lambda authorizer as the single internet entrypoint to the catalog EKS service.
# NOTE: integration_uri should typically be the ARN of an internal NLB listener that fronts the catalog ingress.
module "catalog_api_gateway" {
  source = "../../modules/api_gateway"

  service = "catalog"
  region  = var.DEFAULT_REGION

  # Shared secret token evaluated by the Lambda authorizer.
  authorizer_token = "REPLACE_ME_WITH_STRONG_TOKEN"

  # Use the same private subnets as the EKS worker nodes for the VPC Link,
  # so API Gateway can reach the internal NLB/ALB that frontends the catalog service.
  vpc_link_subnet_ids = module.catalog_network.service_subnet_ids

  # Optionally attach extra SGs to the VPC link ENIs if needed.
  vpc_link_security_group_ids = []

  # ARN of the NLB listener that routes to the catalog service inside the cluster.
  integration_uri = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/net/catalog-nlb/REPLACE_ME/REPLACE_ME"
}
