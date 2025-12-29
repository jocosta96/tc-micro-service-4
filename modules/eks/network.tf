locals {
  network_tags = {
    origin = "tc-micro-service-4/modules/eks/network.tf"
  }
}

locals {
  # Use first CIDR from allowed_ip_cidrs if provided, otherwise empty list (no access)
  deployer_cidr = length(var.allowed_ip_cidrs) > 0 ? var.allowed_ip_cidrs[0] : ""
}


# ===== SECURITY GROUPS =====

# EKS Cluster Security Group
resource "aws_security_group" "ordering_eks_cluster_sg" {
  name_prefix = "${var.service}-eks-cluster-"
  vpc_id      = var.VPC_ID

  tags = merge(local.network_tags, { name = "${var.service}-eks-cluster-sg" })
}

# Allow HTTPS access to EKS API server from allowed IP CIDRs
resource "aws_vpc_security_group_ingress_rule" "eks_api_server_development" {
  count = length(var.allowed_ip_cidrs) > 0 ? 1 : 0

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

# Allow NodePort access from allowed IP CIDRs (for NodePort services and direct pod access)
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_development" {
  count = length(var.allowed_ip_cidrs) > 0 ? 1 : 0

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

resource "aws_lb" "app_nlb" {
  name               = "${var.service}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.SUBNET_IDS
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.service}-tg"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = var.VPC_ID
  target_type = "ip" # Recommended: routes directly to Pod IPs
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
