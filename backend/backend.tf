provider "aws"{
  region = "us-east-1"
}

# -------------------------------
# S3 Bucket for Terraform State
# -------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket11212025new" # Change to a unique name

  tags = {
    Name        = "terraform-state"
    Environment = "infrastructure"
  }
}

# Enable versioning for state history
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption (SSE-S3 by default)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

# -------------------------------
# DynamoDB Table for State Locking
# -------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = "infrastructure"
  }
}

# -------------------------------
# Outputs
# -------------------------------

