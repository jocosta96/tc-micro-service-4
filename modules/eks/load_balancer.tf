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
  protocol    = "TCP"
  vpc_id      = var.VPC_ID
  target_type = "ip"

  health_check {
    protocol            = "HTTP"
    path                = "/health"
    port                = "traffic-port"
    matcher             = "200-299"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
  }
}



resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    # amazonq-ignore-next-line
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  depends_on = [ aws_lb_target_group.app_tg ]
}



