# S3 Bucket for Remote State and Locking the state file

#=============== Setting up S3 Bucket for Remote State ===========================



resource "aws_s3_bucket" "remote" {
  bucket = "${var.env}-bucket-for-terraform-state"
  tags   = merge(var.common_tags, { Name = "${var.common_tags["project"]} S3 Bucket for State File" })
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.remote.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.example]

  bucket = aws_s3_bucket.remote.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.remote.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.remote.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#========================= ENCRYPTION ============================================

resource "aws_kms_key" "encryption" {
  multi_region = var.enable_multi_region
}


resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.remote.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.encryption.id
      sse_algorithm     = "aws:kms"
    }
  }
}

#===================== DynamoDB Table for locking S3 ==============================

resource "aws_dynamodb_table" "state" {
  name           = "${var.env}-table-for-terraform-state"
  read_capacity  = var.read_write_capacity["read"]
  write_capacity = var.read_write_capacity["write"]
  hash_key       = "LockID"
  billing_mode   = "PROVISIONED"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.common_tags, { Name = "${var.common_tags["project"]} DynamoDB Table" })
}


