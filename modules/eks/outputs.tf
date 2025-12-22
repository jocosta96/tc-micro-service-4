output "name" {
  value = aws_eks_cluster.ordering_eks_cluster.name
}

output "node_group_name" {
  value = aws_eks_node_group.ordering_eks_node_group.node_group_name
}