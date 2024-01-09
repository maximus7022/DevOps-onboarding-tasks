module "s3" {
  source      = "./modules/s3"
  bucket_name = var.bucket_name
}

module "lambda" {
  source           = "./modules/lambda"
  role_name        = var.role_name
  lambda_func_name = var.lambda_func_name
  s3_bucket        = module.s3.bucket_name
}
