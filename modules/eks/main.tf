# EKS tags now managed in centralized locals.tf

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  eks_tags = {
    origin = "tc-micro-service-4/modules/eks/main.tf"
  }

  # Use first CIDR from allowed_ip_cidrs if provided, otherwise empty list (no access)
  deployer_cidr = length(var.allowed_ip_cidrs) > 0 ? var.allowed_ip_cidrs[0] : "${chomp(data.http.my_ip.response_body)}/32"

  allowed_ip_cidrs = flatten(concat(var.allowed_ip_cidrs, [local.deployer_cidr]))
}

resource "aws_eks_cluster" "ordering_eks_cluster" {
  name = "${var.service}-eks-cluster"

  access_config {
    authentication_mode = "API"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  role_arn = local.cluster_role_arn
  version  = "1.31"

  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose"]
    node_role_arn = local.node_group_role_arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = length(local.allowed_ip_cidrs) > 0
    public_access_cidrs     = local.allowed_ip_cidrs
    subnet_ids              = var.SUBNET_IDS
  }


}




#resource "aws_eks_addon" "cloudwatch_observability" {
#  cluster_name                = aws_eks_cluster.ordering_eks_cluster.name
#  addon_name                  = "amazon-cloudwatch-observability"
#  service_account_role_arn    = local.cluster_role_arn
#  resolve_conflicts_on_create = "OVERWRITE"
#}
