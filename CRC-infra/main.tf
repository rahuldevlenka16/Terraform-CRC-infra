module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = var.table_name
}

module "lambda" {
  source         = "./modules/lambda"
  function_name  = "visitor-counter"
  role_name      = "visitor-lambda-role"
  policy_name    = "visitor-lambda-policy"
  lambda_zip     = "lambda/lambda.zip"
  table_name     = module.dynamodb.table_name
  dynamodb_arn   = module.dynamodb.table_arn
}

module "api" {
  source              = "./modules/api-gateway"
  api_name            = "visitor-api"
  lambda_invoke_arn   = module.lambda.invoke_arn
  lambda_name         = module.lambda.function_name
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = "cloud-resume-terraform-16-12-2025"
}

module "cloudfront" {
  source        = "./modules/cloudfront"
  bucket_domain = module.s3.bucket_domain
}
