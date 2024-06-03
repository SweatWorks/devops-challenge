
variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "The entry point of the Lambda function"
  type        = string
}

variable "s3_bucket" {
  description = "The S3 bucket containing the Lambda function code"
  type        = string

}

variable "environment" {
  description = "The environment in which the Lambda function is deployed"
  type        = string
}
