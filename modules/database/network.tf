# Detect public IP of the operator to restrict control-plane access during development/deploy
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  deployer_cidr = "${chomp(data.http.my_ip.body)}/32"
  network_tags = {
    origin = "tc-micro-service-4/modules/database/network.tf"
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = var.VPC_ID

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow HTTPS from the admin's IP
resource "aws_vpc_security_group_ingress_rule" "eks_api_server_development" {

  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = local.deployer_cidr
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432

  tags = local.network_tags
}