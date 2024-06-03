
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/${var.function_name}"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.s3_bucket}-${var.environment}"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}-${var.environment}"
  retention_in_days = 7
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
  inline_policy {
    name = "Lambda"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = "arn:aws:logs:*:*:*"
        },
      ]
    })

  }
  inline_policy {
    name = "S3"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
          ]
          Resource = [
            "${aws_s3_bucket.bucket.arn}/*",
          ]
        },
      ]
    })
  }
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  function_name    = "${var.function_name}-${var.environment}"
  handler          = var.handler
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_role.arn
  timeout          = 30
  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.bucket.bucket
    }
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket" {
  bucket = aws_s3_bucket.bucket.bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [aws_lambda_permission.lambda_permission]
}
