provider "aws" {
  region = var.aws-region
  # profile = var.aws-profile

  default_tags {
    tags = {
      Project     = var.aws-profile
      Environment = "Dev"
      ManagedBy   = "terraform"
    }
  }
}
# main vpc 
resource "aws_vpc" "main-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "mainVPC"
  }
}

# # create public, private subnets
# resource "aws_subnet" "subnets" {}

# # create ami
# data "aws_ami" "linux" {}

# # create ec2 instance
# resource "aws_insatnce" "my-ec2-instance" {}

# # create application load balancer
# resource "aws_alb" "name" {}

# # create s3 bucket
# resource "aws_s3_bucket" "my-bucket" {}

# # create iam role for accessing s3 bucket
# resource "aws_iam_role" "s3-access-role" {}

# # create internet gateway 
# resource "aws_internet_gateway" "name" {}

# # create nat gateway
# resource "aws_nat_gateway" "name" {}

# # sg
# resource "aws_security_group" "name" {

# }

# # route table
# resource "aws_route_table" "name" {

# }

# # vpc endpoint for s3
# data "aws_vpc_endpoint" "s3" {

# }
# resource "aws_vpc_endpoint_route_table_association" "name" { }