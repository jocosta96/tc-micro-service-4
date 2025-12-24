# Access entry tags now managed in centralized locals.tf

locals {
  access_entry_tags = {
    origin = "tc-micro-service-4/modules/eks/access_entry.tf"
  }
}

resource "aws_eks_access_entry" "ordering_eks_access_entry" {
  cluster_name  = aws_eks_cluster.ordering_eks_cluster.name
  principal_arn = data.aws_iam_role.lab_role.arn
  type          = "STANDARD"
  tags          = local.access_entry_tags
}

resource "aws_eks_access_policy_association" "ordering_eks_access_policy_association" {
  cluster_name  = aws_eks_cluster.ordering_eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_iam_role.lab_role.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ordering_eks_access_entry]
}

# Add access for voclabs role (current user role in AWS Learning Labs)
resource "aws_eks_access_entry" "ordering_eks_access_entry_voclabs" {
  cluster_name  = aws_eks_cluster.ordering_eks_cluster.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs"
  type          = "STANDARD"
  tags          = local.access_entry_tags
}

resource "aws_eks_access_policy_association" "ordering_eks_access_policy_association_voclabs" {
  cluster_name  = aws_eks_cluster.ordering_eks_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ordering_eks_access_entry_voclabs]
}

# Automatic kubeconfig update after EKS cluster creation
resource "null_resource" "auto_kubeconfig_setup" {

  # Triggers when cluster or access entries change
  triggers = {
    cluster_endpoint = aws_eks_cluster.ordering_eks_cluster.endpoint
    cluster_name     = aws_eks_cluster.ordering_eks_cluster.name
    access_entry     = aws_eks_access_entry.ordering_eks_access_entry_voclabs.principal_arn
  }

  # Update kubeconfig automatically
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.DEFAULT_REGION} --name ${aws_eks_cluster.ordering_eks_cluster.name} --alias ${var.service}-cluster"
  }

  # Verify connection works
  provisioner "local-exec" {
    command = "kubectl config current-context"
  }

  depends_on = [
    aws_eks_cluster.ordering_eks_cluster,
    aws_eks_node_group.ordering_eks_node_group,
    aws_eks_access_entry.ordering_eks_access_entry_voclabs,
    aws_eks_access_policy_association.ordering_eks_access_policy_association_voclabs
  ]
}