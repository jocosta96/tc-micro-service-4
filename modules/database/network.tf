# Detect public IP of the operator to restrict control-plane access during development/deploy
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  deployer_cidr = "${chomp(data.http.my_ip.response_body)}/32"
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

# Allow PostgreSQL access from deployer's IP for local debugging
resource "aws_vpc_security_group_ingress_rule" "deployer_database_access" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = local.deployer_cidr
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432

  tags = merge(local.network_tags, {
    name    = "${var.service}-db-deployer-access"
    purpose = "local-debugging"
  })
}