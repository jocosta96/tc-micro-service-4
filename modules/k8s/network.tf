#ensure api gateway is the only allowed to receive internet traffic
#resource "aws_security_group" "nlb_sg" {
#  name        = "nlb-sg-${var.service}"
#  vpc_id      = var.vpc_id
#  description = "Security group for NLB"
#
#  ingress {
#    from_port   = 80
#    to_port     = 80
#    protocol    = "tcp"
#    cidr_blocks = [var.vpc_cidr]
#  }
#
#  egress {
#    from_port       = 8080
#    to_port         = 8080
#    protocol        = "tcp"
#    security_groups = [var.node_security_group_id]
#  }
#}
