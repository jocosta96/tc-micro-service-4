# EKS tags now managed in centralized locals.tf

locals {
    eks_tags = {
        origin = "tc-micro-service-4/modules/eks/main.tf"
    }
}

resource "aws_eks_cluster" "ordering_eks_cluster" {

  name     = "ordering-eks-cluster"
  version  = "1.31"
  role_arn = local.cluster_role_arn

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids              = var.SUBNET_IDS
    security_group_ids      = [aws_security_group.ordering_eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = var.allow_public_access ? true : false
    public_access_cidrs     = var.allow_public_access ? ["0.0.0.0/0"] : []
  }

  tags = local.eks_tags

  # Remove dependency on IAM role policy attachments since we're using existing LabRole
}



resource "aws_eks_node_group" "ordering_eks_node_group" {
  tags            = local.eks_tags
  cluster_name    = aws_eks_cluster.ordering_eks_cluster.name
  node_group_name = "ordering-eks-node-group"
  node_role_arn   = local.node_group_role_arn
  subnet_ids      = var.SUBNET_IDS
  instance_types  = ["t3.small"] # Mudança: t3.small em vez de t2.micro
  capacity_type   = "ON_DEMAND"  # Mudança: ON_DEMAND em vez de SPOT
  disk_size       = 20
  ami_type        = "AL2023_x86_64_STANDARD" # Especificar AMI type explicitamente



  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Aguardar cluster estar pronto
  depends_on = [aws_eks_cluster.ordering_eks_cluster]
}

## EKS cluster validation using null_resource
#resource "null_resource" "eks_cluster_validation" {
#
#  depends_on = [
#    aws_eks_cluster.ordering_eks_cluster,
#    aws_eks_node_group.ordering_eks_node_group
#  ]
#
#  triggers = {
#    cluster_name     = aws_eks_cluster.ordering_eks_cluster.name
#    cluster_endpoint = aws_eks_cluster.ordering_eks_cluster.endpoint
#    cluster_version  = aws_eks_cluster.ordering_eks_cluster.version
#    node_group_name  = aws_eks_node_group.ordering_eks_node_group.node_group_name
#    timestamp        = timestamp()
#  }
#
#  provisioner "local-exec" {
#    command = "bash ${path.module}/scripts/validate_eks_cluster.sh ${aws_eks_cluster.ordering_eks_cluster.name} ${var.DEFAULT_REGION} ${aws_eks_node_group.ordering_eks_node_group.node_group_name}"
#
#    on_failure = continue
#  }
#}
