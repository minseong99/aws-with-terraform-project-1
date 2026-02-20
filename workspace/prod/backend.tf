terraform {
  backend "s3" {
    bucket         = "my-unique-tfstate-bucket-minseong99-b9uqxxnj"
    region         = "ap-northeast-1"
    dynamodb_table = "my-tf-lock-table"
    key            = "prod/terraform.tfstate"
    encrypt        = true
  }
}