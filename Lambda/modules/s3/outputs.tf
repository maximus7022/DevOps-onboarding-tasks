# \\\\\\\\\\Sharing bucket name with Lambda module//////////
output "bucket_name" {
  value = aws_s3_bucket.s3.bucket
}
