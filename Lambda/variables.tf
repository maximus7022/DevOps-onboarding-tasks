variable "bucket_name" {
  default = "s3-bucket-for-lmbd-output"
}

variable "role_name" {
  default = "LambdaRoleEC2S3"
}

variable "lambda_func_name" {
  default = "EC2healthCheckFunction"
}
