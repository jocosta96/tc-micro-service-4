# Detect public IP of the operator to restrict control-plane access during development/deploy
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  network_tags = {
    origin = "tc-micro-service-4/modules/network/main.tf"
    deployer_cidr = "${chomp(data.http.my_ip.response_body)}/32"
  }
}

resource "aws_vpc" "ordering_vpc" {
  tags                 = local.network_tags
  cidr_block           = var.VPC_CIDR_BLOCK
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "ordering_subnet" {
  tags                    = local.network_tags
  count                   = var.SUBNET_COUNT
  vpc_id                  = aws_vpc.ordering_vpc.id
  cidr_block              = cidrsubnet(var.VPC_CIDR_BLOCK, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = var.AVAILABILITY_ZONES[count.index]
}

resource "aws_subnet" "database_subnet" {
  tags              = local.network_tags
  count             = 2
  vpc_id            = aws_vpc.ordering_vpc.id
  cidr_block        = cidrsubnet(var.VPC_CIDR_BLOCK, 4, 15 - count.index) #total subnets is 16, going on reversal order
  availability_zone = var.AVAILABILITY_ZONES[count.index]
}

resource "aws_db_subnet_group" "ordering_data_subnet_group" {
  name       = "${var.service}-subnet-group"
  subnet_ids = aws_subnet.database_subnet[*].id

  tags = local.network_tags
}

resource "aws_internet_gateway" "ordering_igw" {
  tags   = local.network_tags
  vpc_id = aws_vpc.ordering_vpc.id
}

resource "aws_route_table" "ordering_route_table" {
  tags   = local.network_tags
  vpc_id = aws_vpc.ordering_vpc.id
  route {
    cidr_block = aws_vpc.ordering_vpc.cidr_block
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ordering_igw.id
  }
}

resource "aws_route_table_association" "ordering_route_table_association" {
  count          = var.SUBNET_COUNT
  subnet_id      = aws_subnet.ordering_subnet[count.index].id
  route_table_id = aws_route_table.ordering_route_table.id
}

# Associate database subnets with route table for internet access
# This is required for publicly_accessible RDS instances to be reachable from the internet
resource "aws_route_table_association" "database_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.database_subnet[count.index].id
  route_table_id = aws_route_table.ordering_route_table.id
}