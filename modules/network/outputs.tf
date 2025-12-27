output "service_vpc_cidr_block" {
  value = aws_vpc.ordering_vpc.cidr_block
}

output "service_vpc_id" {
  value = aws_vpc.ordering_vpc.id
}

output "service_subnet_ids" {
  value = aws_subnet.ordering_subnet[*].id
}

output "service_private_subnet_ids" {
  value = aws_subnet.database_subnet[*].id
}

output "service_data_subnet_group_name" {
  value = aws_db_subnet_group.ordering_data_subnet_group.name
}