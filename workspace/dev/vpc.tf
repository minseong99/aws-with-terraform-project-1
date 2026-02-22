# VPC(Virtual Private Cloud) -仮想プライベートの構築
resource "aws_vpc" "main-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-main-vpc"
    Environment = var.environment
  }
}

# Internet Gateway - インターネットへの出入り口
resource "aws_internet_gateway" "main-ig" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name        = "${var.environment}-main-igw"
    Environment = "dev"
  }
}

# public subnet - ALB　＆　Nat Gateway　配置用
resource "aws_subnet" "public-subnets" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.is_public

  tags = {
    Name        = "${var.environment}-${each.key}"
    Environment = var.environment
  }
}


# public route table - ネットワークの道案内
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-ig.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

# public Route Table Association 
resource "aws_route_table_association" "public_association" {
  for_each       = aws_subnet.public-subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}
# ===========================
# Nat Gate way & Elastic IP - プライベートからのインターネット通信用
# ===========================
# Elastic Ip - Nat Gatewayに割り当てる固定IP
resource "aws_eip" "nat_ip" {
  # enable elastic ip 
  count  = var.enable-nat-gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
  }
}
# Nat Gateway - 費用問題のせいで　Public Subnet aのみで配置 
resource "aws_nat_gateway" "ng-public-a" {
  # enable nat gateway
  count         = var.enable-nat-gateway ? 1 : 0
  allocation_id = aws_eip.nat_ip[0].id
  subnet_id     = aws_subnet.public-subnets["public-subnet-a"].id

  tags = {
    Name        = "${var.environment}-nat-gw"
    Environment = var.environment
  }
  # IGWが作られてからNATが外に出ることになるから依存性付与
  depends_on = [aws_internet_gateway.main-ig]

}


# private subnet - DB/Backend配置用
resource "aws_subnet" "private-subnets" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.is_public

  tags = {
    Name        = "${var.environment}-${each.key}"
    Environment = var.environment
  }
}

# private route table 
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
  }
}

# private route table <-> private subnets 
resource "aws_route_table_association" "privates" {
  for_each       = aws_subnet.private-subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private-rt.id
}

# Nat gateway access　route 規則をプライベートテイブルに追加
resource "aws_route" "private-nat-access" {
  count = var.enable-nat-gateway ? 1 : 0

  route_table_id         = aws_route_table.private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ng-public-a[0].id
}




