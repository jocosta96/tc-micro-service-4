resource "aws_security_group" "nlb_sg" {
  name_prefix = "${var.service}-nlb-"
  vpc_id      = var.VPC_ID

  tags = merge(local.network_tags, { name = "${var.service}-nlb-sg" })
}


resource "aws_vpc_security_group_egress_rule" "nlb_egress" {
  security_group_id = aws_security_group.nlb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-nlb-egress" })
}

resource "aws_vpc_security_group_ingress_rule" "nlb_node_ingress" {
  security_group_id            = aws_security_group.nlb_sg.id
  referenced_security_group_id = aws_security_group.ordering_eks_node_sg.id
  ip_protocol                  = "-1"

  tags = merge(local.network_tags, { name = "${var.service}-node-to-node" })
}

resource "aws_lb" "app_nlb" {
  name               = "${var.service}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.SUBNET_IDS
  security_groups   = [aws_security_group.nlb_sg.id]
  enforce_security_group_inbound_rules_on_private_link_traffic = "off"
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.service}-tg"
  port        = 8080
  protocol    = "TCP"        # NLB listener stays TCP
  vpc_id      = var.VPC_ID
  target_type = "ip"

  health_check {
    protocol            = "HTTP"        # MUST be HTTP
    path                = "/health"     # Matches your readiness probe
    port                = "traffic-port" # same as target port
    matcher             = "200-299"     # Accept all 2xx
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10            # allow some response time
    interval            = 30
  }
}


resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}



