variable "bucket_name" {
  default = "s3-bucket-for-lmbd-output"
}

variable "lambda_role_name" {
  default = "LambdaRoleEC2S3"
}

variable "lambda_func_name" {
  default = "EC2healthCheckFunction"
}

variable "instance_ami" {
  default = "ami-07ec4220c92589b40"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "instance_name_tag" {
  default = "grafana"
}

variable "grafana_role_name" {
  default = "GrafanaRoleS3"
}

variable "profile_name" {
  default = "grafana_iam_profile"
}

variable "queue_name" {
  default = "s3-event-notification-queue"
}
