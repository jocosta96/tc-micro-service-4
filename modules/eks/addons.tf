resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.ordering_eks_cluster
  addon_name   = "eks-pod-identity-agent"
}

