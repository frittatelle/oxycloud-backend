#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "download-file"
  description   = "Download file with provided id"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = 30

  source_path = "${path.module}/lambda_src"

  store_on_s3 = false
  environment_variables = {
    USER_STORAGE_TABLE  = var.storage_table.name
    USER_STORAGE_BUCKET = var.storage_bucket_id
  }
}
resource "aws_iam_policy" "lambda_dyndb_get_item" {
  name        = "lambda_dyndb_get_item"
  description = "allows to get item.path from ${var.storage_table.arn}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["dynamodb:GetItem"]
      Effect   = "Allow"
      Resource = "${var.storage_table.arn}"
  }, ] })
}

resource "aws_iam_role_policy_attachment" "lambda_crud_dyndb" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = aws_iam_policy.lambda_dyndb_get_item.arn
}

resource "aws_lambda_permission" "allow_api_gateway_invoke" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/GET/docs/*"
}

