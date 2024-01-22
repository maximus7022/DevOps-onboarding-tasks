
---
# Performing Amazon EC2 health-checks with a Lambda function provisioned by Terraform [deprecated]

## Overview
This documentation outlines the process of `provisioning Amazon Lambda function, that will perform basic health-checks and gather information about EC2 instances`.

## Prerequisites
To reproduce this project in your own environment you'll need:
- `AWS free tier account`
- `Terraform` to provision AWS infrastructure

To be able to provision AWS infrastructure with Terraform you'll need:
- to create corresponding IAM user with administrative rights in AWS Management Console
- to run `aws configure` command with use of created IAM credentials

## Steps to reproduce

### The Python funtion itself
First of all we need to develop the code that we want to run as Lambda function. As an example, we have [`such code`](./source/lambda_function.py):
```python
import os
import time
import json
import boto3

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')
    s3_client = boto3.client('s3')
    
    # EC2 information gathering
    reservations = ec2_client.describe_instances()['Reservations']
    records = []
    
    for reservation in reservations:
      for instance in reservation['Instances']:
        instance_info = {
          "Instance Name": instance['Tags'][0]['Value'],
          "Instance ID": instance['InstanceId'],
          "Instance State": instance['State']['Name']
        }
        if instance['State']['Name'] == 'running':
          status_check_response = ec2_client.describe_instance_status(InstanceIds=[instance['InstanceId']])
          if 'InstanceStatuses' in status_check_response and len(status_check_response['InstanceStatuses']) > 0:
            instance_info.update({
              "Instance status check": status_check_response['InstanceStatuses'][0]['InstanceStatus']['Details'][0]['Status'],
              "System status check": status_check_response['InstanceStatuses'][0]['SystemStatus']['Details'][0]['Status']
            })
        records.append(instance_info)
    
    # pushing gathered info to S3 bucket
    json_output = json.dumps(records, indent=4)
    bucket_name = os.environ["BUCKET"]
    file_name = 'instance_data' + time.strftime("%Y%m%d-%H%M%S") + '.json'
    s3_client.put_object(Body=json_output, Bucket=bucket_name, Key=file_name)
    print(f"JSON data sent to S3 bucket: {bucket_name}/{file_name}")
    return records
```
After execution, this code `collects information about all EC2's` in the region, converts the collected information `to JSON` and sends it to the `S3 bucket`.

### Terraform configuration
Finally, we are ready to provision our `Lambda function`. For this purpose, two [`terraform modules`](./modules/) were used - one for `S3 bucket` creation, and another one for `Lambda`.

**`S3 module contents`**
- `main.tf`:
```hcl
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
```
- `variables.tf`:
```hcl
  variable "bucket_name" {
    type = string
  }
```
- `outputs.tf`:
```hcl
  # \\\\\\\\\\Sharing bucket name with Lambda module//////////
  output "bucket_name" {
    value = aws_s3_bucket.s3.bucket
  }
```

**`Lambda module contents`**
- `iam.tf`:
```hcl
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
```
- `main.tf`:
```hcl
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

  # \\\\\\\\\\Adding function URL to trigger its execution//////////
  resource "aws_lambda_function_url" "lambda_url" {
    function_name      = aws_lambda_function.lambda.function_name
    authorization_type = "AWS_IAM"
  }
```
- `variables.tf`:
```hcl
  variable "role_name" {
    type = string
  }

  variable "lambda_func_name" {
    type = string
  }

  variable "s3_bucket" {
    type = string
  }
```

To apply above config you need to navigate to the [`root project directory`](./) and run such commands:
```bash
  terraform init
```
```bash
  terraform apply
```

## Result
As a result, we have `provisioned with Terraform Lambda function`, that collects info about our EC2 instances and `sends that info in JSON format to S3 bucket`.