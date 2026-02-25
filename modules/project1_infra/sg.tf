# ==================================================
# ALB Security group(インターネットからのWebアクセス許可)
# ==================================================
resource "aws_security_group" "alb-sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security Group for Application Load Balancer"
  vpc_id      = aws_vpc.main-vpc.id


  dynamic "ingress" {
    # http, https
    for_each = local.alb_port
    iterator = alb_port

    content {
      from_port   = alb_port.value
      to_port     = alb_port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# ==================================================
# Bastion host Security Group(管理者用のアクセス許可)
# ==================================================
resource "aws_security_group" "bastion-sg" {
  name        = "${var.environment}-bastion-sg"
  description = "Security Group for Bastion host"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-bastion-sg"
    Environment = var.environment
  }
}

# ==================================================
# Private EC2 Instance Security Group(ALBとBastionからのアクセスのみ許可)
# ==================================================
resource "aws_security_group" "private-ec2-sg" {
  name        = "${var.environment}-private-ec2-sg"
  description = "Security for Private EC2 Instance"
  vpc_id      = aws_vpc.main-vpc.id


  # Alb 許可
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }

  # Bastion 許可
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-private-ec2-sg"
    Environment = var.environment
  }
}