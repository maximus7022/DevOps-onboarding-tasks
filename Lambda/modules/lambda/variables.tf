data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "EC2ReadOnly" {
  name = "AmazonEC2ReadOnlyAccess"
}

data "aws_iam_policy" "S3FullAccess" {
  name = "AmazonS3FullAccess"
}

variable "role_name" {
  type = string
}

variable "lambda_func_name" {
  type = string
}

variable "s3_bucket" {
  type = string
}
