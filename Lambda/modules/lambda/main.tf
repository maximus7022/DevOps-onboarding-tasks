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

# \\\\\\\\\\Cloudwatch Events auto trigger every 1 minute//////////
resource "aws_cloudwatch_event_rule" "event_rule" {
  name                = "lambda-trigger"
  description         = "Fires every 1 minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule      = aws_cloudwatch_event_rule.event_rule.name
  target_id = aws_lambda_function.lambda.id
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "cloudwatch_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule.arn
}
