output "name" {
  value = aws_eks_cluster.ordering_eks_cluster.name
}

output "node_group_name" {
  value = aws_eks_node_group.ordering_eks_node_group.node_group_name
}

output "eks_security_group_id" {
  value = aws_security_group.ordering_eks_cluster_sg.id
}