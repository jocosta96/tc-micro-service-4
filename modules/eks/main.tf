# EKS tags now managed in centralized locals.tf

locals {
  eks_tags = {
    origin = "tc-micro-service-4/modules/eks/main.tf"
  }
}

resource "aws_eks_cluster" "ordering_eks_cluster" {

  name     = "${var.service}-eks-cluster"
  version  = "1.32"
  role_arn = data.aws_iam_role.lab_role.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids              = var.SUBNET_IDS
    security_group_ids      = [
      aws_security_group.ordering_eks_cluster_sg.id, 
      aws_security_group.ordering_eks_node_sg.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = length(local.allowed_ip_cidrs) > 0
    public_access_cidrs     = length(local.allowed_ip_cidrs) > 0 ? local.allowed_ip_cidrs : []
  }

  tags = local.eks_tags

  # Remove dependency on IAM role policy attachments since we're using existing LabRole
}



resource "aws_eks_node_group" "ordering_eks_node_group" {
  tags            = local.eks_tags
  cluster_name    = aws_eks_cluster.ordering_eks_cluster.name
  node_group_name = "${var.service}-eks-node-group"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = var.SUBNET_IDS
  instance_types  = [var.NODE_INSTANCE_TYPE] # Mudança: t3.small em vez de t2.micro
  capacity_type   = "ON_DEMAND"              # Mudança: ON_DEMAND em vez de SPOT
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

  remote_access {
    ec2_ssh_key = var.key_pair_name
    source_security_group_ids = [
      var.bastion_security_group_id, 
      aws_security_group.ordering_eks_node_sg.id
    ]
  }


  # Aguardar cluster estar pronto
  depends_on = [aws_eks_cluster.ordering_eks_cluster]
}



