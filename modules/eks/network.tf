locals {
  network_tags = {
    origin = "tc-micro-service-4/modules/eks/network.tf"
  }
}

# Detect public IP of the operator to restrict control-plane access during development/deploy
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  deployer_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}


# ===== SECURITY GROUPS =====

# EKS Cluster Security Group
resource "aws_security_group" "ordering_eks_cluster_sg" {
  name_prefix = "${var.service}-eks-cluster-"
  vpc_id      = var.VPC_ID

  tags = merge(local.network_tags, { name = "${var.service}-eks-cluster-sg" })
}

# Allow HTTPS access to EKS API server (development environments)
resource "aws_vpc_security_group_ingress_rule" "eks_api_server_development" {

  security_group_id = aws_security_group.ordering_eks_cluster_sg.id
  cidr_ipv4         = local.deployer_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443

  tags = merge(local.network_tags, { name = "${var.service}-eks-api-development" })
}

# Allow traffic from worker nodes
resource "aws_vpc_security_group_ingress_rule" "eks_cluster_ingress_node_https" {
  security_group_id            = aws_security_group.ordering_eks_cluster_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_node_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443

  tags = merge(local.network_tags, { name = "${var.service}-eks-cluster-from-nodes" })
}

# EKS Worker Node Security Group
resource "aws_security_group" "ordering_eks_node_sg" {
  name_prefix = "${var.service}-eks-node-"
  vpc_id      = var.VPC_ID

  tags = merge(local.network_tags, { name = "${var.service}-eks-node-sg" })
}

# Allow worker nodes to communicate with cluster API server
resource "aws_vpc_security_group_ingress_rule" "eks_node_ingress_cluster" {
  security_group_id            = aws_security_group.ordering_eks_node_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_cluster_sg.id
  from_port                    = 1025
  ip_protocol                  = "tcp"
  to_port                      = 65535

  tags = merge(local.network_tags, { name = "${var.service}-node-from-cluster" })
}

# Allow NodePort access from deployer IP (for NodePort services and direct pod access)
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_development" {

  security_group_id = aws_security_group.ordering_eks_node_sg.id
  cidr_ipv4         = local.deployer_cidr
  from_port         = 30000
  ip_protocol       = "tcp"
  to_port           = 32767

  tags = merge(local.network_tags, { name = "${var.service}-eks-nodeport-development" })
}

# Allow worker nodes to communicate with each other
resource "aws_vpc_security_group_ingress_rule" "eks_node_ingress_self" {
  security_group_id            = aws_security_group.ordering_eks_node_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_node_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-node-to-node" })
}

# Egress rules - Allow all outbound traffic
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