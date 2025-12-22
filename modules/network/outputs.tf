output "service_vpc_cidr_block" {
  value = aws_vpc.ordering_vpc.cidr_block
}

output "service_vpc_id" {
  value = aws_vpc.ordering_vpc.id
}

output "service_subnet_ids" {
  value = aws_subnet.ordering_subnet[*].id
}