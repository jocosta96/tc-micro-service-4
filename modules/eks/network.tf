############################
# Public IP discovery
############################

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Get EKS cluster information to access the cluster security group
data "aws_eks_cluster" "cluster" {
  name = "${var.service}-eks-cluster"
  depends_on = [
    aws_eks_cluster.ordering_eks_cluster
  ]
}

############################
# Locals
############################

locals {
  network_tags = {
    origin = "tc-micro-service-4/modules/eks/network.tf"
  }

  # Always get current IP - works for both local and GitHub Actions
  deployer_cidr = "${chomp(data.http.my_ip.response_body)}/32"
  eks_managed_sg = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id

  # Deduplicate IPs using setsubtract to avoid duplicate rules
  unique_allowed_cidrs = setsubtract(var.allowed_ip_cidrs, [local.deployer_cidr])
  all_allowed_cidrs = concat([local.deployer_cidr], local.unique_allowed_cidrs)
}

############################
# Secutiry Groups
############################

resource "aws_security_group" "ordering_eks_cluster_sg" {
  name_prefix = "${var.service}-eks-cluster-"
  vpc_id      = var.VPC_ID

  tags = merge(local.network_tags, {
    name = "${var.service}-eks-cluster-sg"
  })
}

resource "aws_security_group" "ordering_eks_node_sg" {
  name_prefix = "${var.service}-eks-node-"
  vpc_id      = var.VPC_ID

  tags = merge(local.network_tags, {
    name = "${var.service}-eks-node-sg"
  })
}

resource "aws_security_group" "nlb_sg" {
  name_prefix = "${var.service}-nlb-"
  vpc_id      = var.VPC_ID

  tags = merge(local.network_tags, { name = "${var.service}-nlb-sg" })
}

############################
# Internal Ingress Trafic (all open)
############################

############# NLB INGRESS ###############

# NODE > NLB
resource "aws_vpc_security_group_ingress_rule" "nlb_node_ingress" {
  security_group_id            = aws_security_group.nlb_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_node_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-node-to-nlb" })
}

# CLUSTER > NLB
resource "aws_vpc_security_group_ingress_rule" "nlb_cluster_ingress" {
  security_group_id            = aws_security_group.nlb_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_cluster_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-cluster-to-nlb" })
}

# BASTION > NLB
resource "aws_vpc_security_group_ingress_rule" "nlb_bastion_ingress" {
  security_group_id            = aws_security_group.nlb_sg.id
  referenced_security_group_id = var.bastion_security_group_id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-bastion-to-nlb" })
}

# CLUSTER INGRESS

# BASTION > CLUSTER
resource "aws_vpc_security_group_ingress_rule" "cluster_bastion_ingress" {
  security_group_id            = aws_security_group.ordering_eks_cluster_sg.id
  referenced_security_group_id = var.bastion_security_group_id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-bastion-to-cluster" })
}

# NODE > CLUSTER
resource "aws_vpc_security_group_ingress_rule" "eks_cluster_from_nodes" {
  security_group_id            = aws_security_group.ordering_eks_cluster_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_node_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, {
    name = "${var.service}-node-cluster"
  })
}

# NODE INGRESS

# BASTION > NODE
resource "aws_vpc_security_group_ingress_rule" "node_bastion_ingress" {
  security_group_id            = aws_security_group.ordering_eks_node_sg.id
  referenced_security_group_id = var.bastion_security_group_id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-bastion-to-cluster" })
}


# CLUSTER > NODE
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_cluster" {
  security_group_id            = aws_security_group.ordering_eks_node_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_cluster_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, {
    name = "${var.service}-cluster-to-node"
  })
}


# NODE > NODE
resource "aws_vpc_security_group_ingress_rule" "eks_node_ingress_self" {
  security_group_id            = aws_security_group.ordering_eks_node_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_node_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, {
    name = "${var.service}-node-to-node"
  })
}

# NLB > NODE
resource "aws_vpc_security_group_ingress_rule" "nlb_to_node" {
  security_group_id            = aws_security_group.ordering_eks_node_sg.id
  referenced_security_group_id = aws_security_group.nlb_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, {
    name = "${var.service}-nlb-to-node"
  })
}

# NLB > EKS CLUSTER (EKS-managed security group)
resource "aws_vpc_security_group_ingress_rule" "nlb_to_eks_cluster" {
  security_group_id            = local.eks_managed_sg
  referenced_security_group_id = aws_security_group.nlb_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, {
    name = "${var.service}-nlb-to-eks-cluster"
  })
}

############################
# External Ingress
############################

# Allow current deployer IP for EKS API access
resource "aws_vpc_security_group_ingress_rule" "eks_api_deployer" {
  security_group_id = aws_security_group.ordering_eks_cluster_sg.id
  cidr_ipv4         = local.deployer_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = merge(local.network_tags, {
    name = "${var.service}-eks-api-deployer"
  })
}

# Allow additional configured IPs (excluding deployer IP to avoid duplicates)
resource "aws_vpc_security_group_ingress_rule" "eks_api_additional" {
  count = length(local.unique_allowed_cidrs)

  security_group_id = aws_security_group.ordering_eks_cluster_sg.id
  cidr_ipv4         = local.unique_allowed_cidrs[count.index]
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = merge(local.network_tags, {
    name = "${var.service}-eks-api-additional-${count.index}"
  })
}

# Optional: NodePort access (dev only)
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_nodeport_dev" {
  count = length(local.all_allowed_cidrs) > 0 ? 1 : 0

  security_group_id = aws_security_group.ordering_eks_node_sg.id
  cidr_ipv4         = local.deployer_cidr
  from_port         = 30000
  to_port           = 32767
  ip_protocol       = "tcp"

  tags = merge(local.network_tags, {
    name = "${var.service}-nodeport-dev"
  })
}

# Optional: NLB access (dev only)
resource "aws_vpc_security_group_ingress_rule" "nlb_dev" {
  count = length(local.all_allowed_cidrs) > 0 ? 1 : 0

  security_group_id = aws_security_group.nlb_sg.id
  cidr_ipv4         = local.deployer_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  tags = merge(local.network_tags, {
    name = "${var.service}-nodeport-dev"
  })
}

############################
# EGRESS RULES
############################

resource "aws_vpc_security_group_egress_rule" "eks_cluster_egress" {
  security_group_id = aws_security_group.ordering_eks_cluster_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-cluster-egress" })
}

resource "aws_vpc_security_group_egress_rule" "eks_node_egress" {
  security_group_id = aws_security_group.ordering_eks_node_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-node-egress" })
}

resource "aws_vpc_security_group_egress_rule" "nlb_egress" {
  security_group_id = aws_security_group.nlb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-nlb-egress" })
}