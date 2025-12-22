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

