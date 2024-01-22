data "aws_iam_policy_document" "grafana_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "grafana_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role_policy.json
}

data "aws_iam_policy" "GrafanaCloudWatchAccess" {
  name = "AmazonGrafanaCloudWatchAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_atachment" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = data.aws_iam_policy.GrafanaCloudWatchAccess.arn
}

data "aws_iam_policy" "S3ReadOnlyAccess" {
  name = "AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "s3_policy_atachment" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = data.aws_iam_policy.S3ReadOnlyAccess.arn
}

resource "aws_iam_policy" "SQSReceiveDeleteAccess" {
  name        = "AmazonSQSReceiveDeleteAccess"
  description = "Allows receiving and deleting messages from SQS"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "${var.queue_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sqs_policy_atachment" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = resource.aws_iam_policy.SQSReceiveDeleteAccess.arn
}

resource "aws_iam_instance_profile" "grafana_profile" {
  name = var.profile_name
  role = aws_iam_role.grafana_role.name
}
