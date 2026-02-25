
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

module "dev-infra" {
  source = "../../modules/project1_infra"

  aws-region         = "ap-northeast-1"
  environment        = "dev"
  enable-nat-gateway = true
  enable-compute     = true
}