locals {
  network_tags = {
    origin = "tc-micro-service-4/modules/database/network.tf"
  }
}

resource "aws_security_group" "db_sg" {
  name_prefix = "${var.service}-db-"
  vpc_id      = var.VPC_ID
  description = "Security group for ${var.service} database"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = length(var.allowed_security_groups) > 0 ? var.allowed_security_groups : []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.network_tags, {
    Name = "${var.service}-db-sg"
  })
}
