# \\\\\\\\\\Creating IAM Role, to provide Lambda function with specific permissions//////////
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# \\\\\\\\\\Ensuring EC2 read only permission//////////
data "aws_iam_policy" "EC2ReadOnly" {
  name = "AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_policy_atachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.EC2ReadOnly.arn
}

# \\\\\\\\\\Ensuring S3 object upload only permission//////////
data "aws_iam_policy_document" "S3PutOnly_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "S3PutOnly" {
  name        = "AmazonS3PutOnlyAccess"
  description = "Policy allowing only object uploads to S3 bucket"
  policy      = data.aws_iam_policy_document.S3PutOnly_document.json
}

resource "aws_iam_role_policy_attachment" "s3_policy_atachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.S3PutOnly.arn
}
