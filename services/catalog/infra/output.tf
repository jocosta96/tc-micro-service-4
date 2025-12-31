
  output "cluster_name" {value = module.catalog_eks.name}
  output "cluster_endpoint" {value = module.catalog_eks.endpoint}
  output "cluster_certificate_authority_data" {value = module.catalog_eks.certificate_authority_data}
  output "vpc_id" {value = module.catalog_network.service_vpc_id}
  output "vpc_cidr" {value = module.catalog_network.service_vpc_cidr_block}
  output "node_security_group_id" {value = module.catalog_eks.eks_node_security_group_id}
  output "eks_load_balancer_arn" {value = module.catalog_eks.eks_load_balancer_arn}
  output "eks_target_group_arn" {value = module.catalog_eks.eks_target_group_arn}