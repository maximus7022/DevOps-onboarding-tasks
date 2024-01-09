resource "aws_iam_role" "lambda_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_policy_atachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.EC2ReadOnly.arn
}

resource "aws_iam_role_policy_attachment" "s3_policy_atachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.S3FullAccess.arn
}

data "archive_file" "func" {
  type        = "zip"
  source_file = "source/lambda_function.py"
  output_path = "source/lambda_function.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = "source/lambda_function.zip"
  function_name    = var.lambda_func_name
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.10"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.func.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      BUCKET = var.s3_bucket
    }
  }
}
