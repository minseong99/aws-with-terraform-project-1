variable "aws-region" {
  description = "The main region for aws"
  type        = string
  # default     = "ap-northeast-1" # tokyo
}

# variable "aws-profile" {
#   description = "This is profile for aws credentials"
#   type        = string
#   # default     = "project_1"
# }

variable "environment" {
  description = "This is environment value."
  type        = string
}

variable "enable-nat-gateway" {
  description = "NAT Gateway 生成するトリガー"
  type        = bool
}

variable "enable-compute" {
  description = "ASG および Bastion host 生成トリガー"
  type        = bool
}

