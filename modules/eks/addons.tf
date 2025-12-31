resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.ordering_eks_cluster.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = aws_eks_cluster.ordering_eks_cluster.name
  addon_name                  = "amazon-cloudwatch-observability"
  service_account_role_arn    = data.aws_iam_role.lab_role.arn
  resolve_conflicts_on_create = "OVERWRITE"
}
