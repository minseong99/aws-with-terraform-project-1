locals {
  public_subnets = {
    public-subnet-a = {
      cidr_block        = "10.0.1.0/24",
      availability_zone = "${var.aws-region}a"
      is_public         = true
    },
    public-subnet-b = {
      cidr_block        = "10.0.2.0/24",
      availability_zone = "${var.aws-region}c"
      is_public         = true
    }
  }
  private_subnets = {
    private-subnet-a = {
      cidr_block        = "10.0.3.0/24",
      availability_zone = "${var.aws-region}a"
      is_public         = false
    },
    private-subnet-b = {
      cidr_block        = "10.0.4.0/24",
      availability_zone = "${var.aws-region}c"
      is_public         = false
    }
  }
  alb_port = [80, 443]
}