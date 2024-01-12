# \\\\\\\\\\S3 bucket creation//////////
resource "aws_s3_bucket" "s3" {
  bucket        = var.bucket_name
  force_destroy = true
}

# \\\\\\\\\\Adding bucket versioning//////////
resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.s3.id
  versioning_configuration {
    status = "Enabled"
  }
}
