# ==============================================================================
# 1. Application Load Balancer 
# ==============================================================================
resource "aws_lb" "main" {
  count = var.enable-compute ? 1 : 0

  name               = "${var.environment}-alb"
  internal           = false # 外部のインターネット通信のため
  load_balancer_type = "application"
  
  security_groups = [aws_security_group.alb-sg.id]

  subnets = [
    aws_subnet.public-subnets["public-subnet-a"].id,
    aws_subnet.public-subnets["public-subnet-b"].id
  ]

  tags = {
    Name = "${var.environment}-alb"
  }
}

# ==============================================================================
# 2. Target Group (ターゲットグループ )
# ==============================================================================

resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  #　health check: ３０秒ごとにサーバが生きているか確認
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200"
  }
}

# ==============================================================================
# 3. Listener (リスナ)
# ==============================================================================
resource "aws_lb_listener" "http" {
  count = var.enable-compute ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  # target groupにtrafficを送る
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}