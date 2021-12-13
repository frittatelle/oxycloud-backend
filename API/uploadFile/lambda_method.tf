#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_method" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "upload-file-method"
  description   = "Generate presigned upload url"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = 30

  source_path = "${path.module}/lambda_src/method"

  store_on_s3 = false
  environment_variables = {
    USER_STORAGE_BUCKET = var.storage_bucket_id
  }
}
resource "aws_iam_policy" "lambda_s3_putobj" {
  name        = "lambda_s3_putobj"
  description = "allows to put object into ${var.storage_bucket_arn}"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
       {
          Action   = ["s3:PutObject"]
          Effect   = "Allow"
          Resource = "${var.storage_bucket_arn}/*"
        },
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_putobj_s3" {
  role       = module.lambda_method.lambda_role_name
  policy_arn = aws_iam_policy.lambda_s3_putobj.arn
}

resource "aws_lambda_permission" "allow_api_gateway_invoke" {
  statement_id  = "AllowApiGatewayInvokeUploadLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_method.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.UploadDoc.http_method}${var.parent_resource_path}"
}

