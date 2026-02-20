
resource "random_id" "s3-bucket-id" {
  byte_length = 6
}

# 1. s3 bucket for terraform state
resource "aws_s3_bucket" "s3-for-state" {
  bucket = "my-unique-tfstate-bucket-minseong99-${lower(random_id.s3-bucket-id.id)}"

  # bucketを過ちで削除することを防ぐ
  lifecycle {
    prevent_destroy = true
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.s3-for-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption -> 状態file暗語化
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryotion" {
  bucket = aws_s3_bucket.s3-for-state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2. Create DynamoDB Table
resource "aws_dynamodb_table" "terraform_state_locks" {
  name         = "my-tf-lock-table"
  billing_mode = "PAY_PER_REQUEST" # 使った料金だけ払う

  # 規則　:　terraformがLockする時と探す固定されたkey
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S" # String 
  }
}


# 3. output 
output "s3_bucket_name" {
  description = "Terraform State S3 Bucket Name"
  value       = aws_s3_bucket.s3-for-state.id
}

output "dynamodb_table_name" {
  description = "Terraform State Lock DynamoDB Table Name"
  value       = aws_dynamodb_table.terraform_state_locks.name
}