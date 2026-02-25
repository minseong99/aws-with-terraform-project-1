
provider "aws" {
  region = "ap-northeast-1"
  # profile = var.aws-profile

  default_tags {
    tags = {
      Project     = "project_1"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "my-unique-tfstate-bucket-minseong99-b9uqxxnj"
    region         = "ap-northeast-1"
    dynamodb_table = "my-tf-lock-table"
    key            = "prod/terraform.tfstate"
    encrypt        = true
  }
}

module "prod-infra" {
  source = "../../modules/project1_infra"

  aws-region  = "ap-northeast-1"
  environment = "prod"

  enable-nat-gateway = var.enable-nat-gateway
  enable-compute     = var.enable-compute
}