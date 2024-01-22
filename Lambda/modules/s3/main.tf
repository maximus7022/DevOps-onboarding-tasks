# \\\\\\\\\\S3 bucket creation//////////
resource "aws_s3_bucket" "s3" {
  bucket        = var.bucket_name
  force_destroy = true
}

# \\\\\\\\\\Bucket versioning//////////
resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

# \\\\\\\\\\SQS queue for unprocessed messages//////////
resource "aws_sqs_queue" "dead_letter_sqs" {
  name = "dead-letter-${var.queue_name}"
}

resource "aws_sqs_queue_redrive_allow_policy" "redrive_allow_policy" {
  queue_url = aws_sqs_queue.dead_letter_sqs.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.main_sqs.arn]
  })
}

# \\\\\\\\\\SQS queue for object creation notification//////////
resource "aws_sqs_queue" "main_sqs" {
  name                      = var.queue_name
  policy                    = data.aws_iam_policy_document.sqs_policy.json
  receive_wait_time_seconds = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_sqs.arn
    maxReceiveCount     = 2
  })
}

# \\\\\\\\\\Bucket SQS notification about object creation//////////
resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = aws_s3_bucket.s3.id

  queue {
    queue_arn     = aws_sqs_queue.main_sqs.arn
    events        = ["s3:ObjectCreated:Put"]
    filter_prefix = "instance_data"
  }
}
