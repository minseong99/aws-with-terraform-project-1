variable "aws-region" {
    description = "The main region for aws"
    type = string
    default = "ap-northeast-1"  # tokyo
}

variable "aws-profile" {
    description = "This is profile for aws credentials"
    type = string
    default = "project_1"
}

variable "environment" {
    description = "This is environment value."
    type = string
    default = "dev"
}