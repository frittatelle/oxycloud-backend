#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "document-on_upload"
  description   = "Callback on upload of a object into the storage bucket. NB it can be a new file as an overide"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true
  
  timeout       = 30

  source_path = "${path.module}/lambda_src"

  store_on_s3 = false
  environment_variables = {
    USER_STORAGE_TABLE = var.storage_table.name
    USER_STORAGE_BUCKET = var.storage_bucket_id
  }
}
resource "aws_iam_policy" "putitem_into_dyndb_for_upload_api" {
  name        = "putitem_into_dyndb_for_upload-api"
  description = "allows to put item into ${var.storage_table.arn} (for the lamda of upload api)"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = ["dynamodb:PutItem"]
        Effect   = "Allow"
        Resource = "${var.storage_table.arn}"
      },]})
}

resource "aws_iam_role_policy_attachment" "lambda_crud-dyndb" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = aws_iam_policy.putitem_into_dyndb_for_upload_api.arn
}

resource "aws_s3_bucket_notification" "triggers" {
  bucket = var.storage_bucket_id

  #count = var.on_created_lambda_arn == null ? 0 : 1

  lambda_function {
    lambda_function_arn = module.lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

}

resource "aws_lambda_permission" "allow_bucket_on_created" {
  statement_id  = "AllowExecutionFromS3BucketOnCreated"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.storage_bucket_arn 
}

