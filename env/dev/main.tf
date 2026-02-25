
provider "aws" {
  region = "ap-northeast-1"
  # profile = var.aws-profile

  default_tags {
    tags = {
      Project     = "project_1"
      Environment = "Dev"
      ManagedBy   = "terraform"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "my-unique-tfstate-bucket-minseong99-b9uqxxnj"
    region         = "ap-northeast-1"
    dynamodb_table = "my-tf-lock-table"
    key            = "dev/terraform.tfstate"
    encrypt        = true
  }
}

variable "enable-nat-gateway" {
  description = "NAT Gateway enable"
  type        = bool
  default     = false 
}

variable "enable-compute" {
  description = "EC2およびASG enable"
  type        = bool
  default     = false
}


module "dev-infra" {
  source = "../../modules/project1_infra"

  aws-region         = "ap-northeast-1"
  environment        = "dev"
  enable-nat-gateway = var.enable-nat-gateway
  enable-compute     = var.enable-compute
}