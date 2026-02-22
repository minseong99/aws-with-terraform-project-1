
# IAM Role 
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  # 信頼政策　ー　このIAMRoleはec2だけ使用できるような政策
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IamRoleに政策追加
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  # 全てのS3にアクセス可能
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#　SSM Session Manager 
resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# 3. instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name 
}