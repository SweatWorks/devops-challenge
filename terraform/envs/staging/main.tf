locals {
  lambda_function_name = "resizePhoto"
  lambda_handler       = "src/lambda.handler"
  s3_bucket            = "bw5mnukhqqvdw7du-photos-bucket"
  environment          = "staging"
}
