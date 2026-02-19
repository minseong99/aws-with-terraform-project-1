provider "aws" {
  region = "ap-northeast-1" # 東京
}

# 1. GitHub Actionsを利用するためのOIDC(OpenID Connect)資格証明生成
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612", "6938fd4d98bab03faadb97b34396831e3780aea1"] 
  # (最新 GitHub OIDC 証明書 2個)
}

# 2. GitHub パイプラインが使う　IAM Role生成
resource "aws_iam_role" "github_actions" {
  name = "github-actions-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" = "repo:minseong99/aws-with-terraform-project-1:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# 3. IAM Roleに AdministratorAccess (最高権限) 付与
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 4. 出力値: パイプラインに使う ARN 値出力
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "これはGitHub Actions パイプラインに入力する IAM Role ARNです"
}