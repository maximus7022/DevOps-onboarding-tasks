# \\\\\\\\\Packing function source code in archive//////////
data "archive_file" "func" {
  type        = "zip"
  source_file = "source/lambda_function.py"
  output_path = "source/lambda_function.zip"
}

# \\\\\\\\\\Lambda function creation//////////
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

# \\\\\\\\\\Adding function URL//////////
resource "aws_lambda_function_url" "lambda_url" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "AWS_IAM"
}
