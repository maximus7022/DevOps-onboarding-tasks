module "s3" {
  source           = "./modules/s3"
  bucket_name      = var.bucket_name
  grafana_role_arn = module.grafana.grafana_role_arn
  queue_name       = var.queue_name
}

module "lambda" {
  source           = "./modules/lambda"
  role_name        = var.lambda_role_name
  lambda_func_name = var.lambda_func_name
  s3_bucket        = module.s3.bucket_name
}

module "grafana" {
  source            = "./modules/grafana"
  instance_ami      = var.instance_ami
  instance_type     = var.instance_type
  instance_name_tag = var.instance_name_tag
  role_name         = var.grafana_role_name
  s3_bucket         = module.s3.bucket_name
  profile_name      = var.profile_name
  queue_arn         = module.s3.queue_arn
}
