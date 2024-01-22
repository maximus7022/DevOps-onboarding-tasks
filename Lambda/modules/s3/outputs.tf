# \\\\\\\\\\Sharing bucket name with Lambda module//////////
output "bucket_name" {
  value = aws_s3_bucket.s3.bucket
}

output "queue_arn" {
  value = aws_sqs_queue.main_sqs.arn
}
