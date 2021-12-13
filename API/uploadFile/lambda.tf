#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_trigger" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "upload-file-trigger"
  description   = "Callback on upload of a object into the storage bucket. NB it can be a new file as an overide"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = 30

  source_path = "${path.module}/lambda_src/trigger"

  store_on_s3 = false
  environment_variables = {
    USER_STORAGE_TABLE  = var.storage_table.name
    USER_STORAGE_BUCKET = var.storage_bucket_id
  }
}
resource "aws_iam_policy" "lambda_putitem_s3head" {
  name        = "lambda_putitem_s3head"
  description = "Allows to put item into ${var.storage_table.arn} and to call the HEAD method on a s3 object"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:PutItem"]
        Effect   = "Allow"
        Resource = "${var.storage_table.arn}"
      },
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "${var.storage_bucket_arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_putitem_s3head" {
  role       = module.lambda_trigger.lambda_role_name
  policy_arn = aws_iam_policy.lambda_putitem_s3head.arn
}

resource "aws_s3_bucket_notification" "triggers" {
  bucket = var.storage_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda_trigger.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

}

resource "aws_lambda_permission" "allow_bucket_on_created" {
  statement_id  = "AllowExecutionFromS3BucketOnCreated"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_trigger.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.storage_bucket_arn
}

