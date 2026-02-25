
# Data Source 
data "aws_region" "current" {}

# S3 VPC Gateway Endpoint 
resource "aws_vpc_endpoint" "s3" {
  vpc_id = aws_vpc.main-vpc.id

  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  # 重要
  vpc_endpoint_type = "Gateway"

  tags = {
    Name        = "${var.environment}-s3-endpoint"
    Environment = var.environment
  }
}

# Route Table Association 
resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  route_table_id = aws_route_table.private-rt.id

  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}