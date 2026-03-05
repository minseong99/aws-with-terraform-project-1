# 最新のUbuntu 22.04 LTS OS image 
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion host in public subnet A 
resource "aws_instance" "bastion" {
  count         = var.enable-compute ? 1 : 0
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public-subnets["public-subnet-b"].id

  vpc_security_group_ids = [aws_security_group.bastion-sg.id]

  #key_name = ""
}

# Launch Template - 起動テンプレート
resource "aws_launch_template" "web_template" {
  name_prefix   = "${var.environment}-web-template-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.private-ec2-sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  user_data = base64encode(
    <<-EOF
        #!/bin/bash

        # interent 接続を確認
        until ping -c1 8.8.8.8 &> /dev/null; do
          echo "インターネットの接続を待機しています。"
          sleep 5
        done

        apt-get update -y
        apt-get install -y git docker.io docker-compose-v2

        systemctl start docker
        systemctl enable docker
        usermod -aG docker ubuntu
        EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-asg-web-server"
    }
  }
}


# Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name             = "${var.environment}-web-asg"
  desired_capacity = var.enable-compute ? 2 : 0
  min_size         = var.enable-compute ? 2 : 0
  max_size         = var.enable-compute ? 4 : 0

  vpc_zone_identifier = [
    aws_subnet.private-subnets["private-subnet-a"].id,
    aws_subnet.private-subnets["private-subnet-b"].id
  ]


  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }

  ## load balancerアクセス
  target_group_arns = [aws_lb_target_group.web.arn]

  health_check_grace_period = 300
  health_check_type         = "EC2"

  # EC2がNat gatewayより素早く作られるのでuser_dataでインタネット接続ができない問題を予防
  depends_on = [ 
    aws_nat_gateway.ng-public-a,
    aws_route.private-nat-access
   ]
}