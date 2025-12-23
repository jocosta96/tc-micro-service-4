# EKS tags now managed in centralized locals.tf

locals {
  eks_tags = {
    origin = "tc-micro-service-4/modules/eks/main.tf"
  }
}

resource "aws_eks_cluster" "ordering_eks_cluster" {

  name     = "${var.service}-eks-cluster"
  version  = "1.34"
  role_arn = local.cluster_role_arn

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids              = var.SUBNET_IDS
    security_group_ids      = [aws_security_group.ordering_eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = [local.deployer_cidr]
  }

  tags = local.eks_tags

  # Remove dependency on IAM role policy attachments since we're using existing LabRole
}



resource "aws_eks_node_group" "ordering_eks_node_group" {
  tags            = local.eks_tags
  cluster_name    = aws_eks_cluster.ordering_eks_cluster.name
  node_group_name = "${var.service}-eks-node-group"
  node_role_arn   = local.node_group_role_arn
  subnet_ids      = var.SUBNET_IDS
  instance_types  = [var.NODE_INSTANCE_TYPE] # Mudança: t3.small em vez de t2.micro
  capacity_type   = "ON_DEMAND"  # Mudança: ON_DEMAND em vez de SPOT
  disk_size       = 20
  ami_type        = var.NODE_AMI_TYPE # Especificar AMI type explicitamente

  scaling_config {
    desired_size = var.SCALING_CONFIG.desired_size
    max_size     = var.SCALING_CONFIG.max_size
    min_size     = var.SCALING_CONFIG.min_size
  }

  update_config {
    max_unavailable = 1
  }

  # Aguardar cluster estar pronto
  depends_on = [aws_eks_cluster.ordering_eks_cluster]
}
