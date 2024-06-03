
module "lambda_function_resize_photo" {
  source        = "../../modules/lambda"
  function_name = local.lambda_function_name
  handler       = local.lambda_handler
  s3_bucket     = local.s3_bucket
  environment   = local.environment
}
