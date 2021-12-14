#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "unshare-file"
  description   = "Unshare file with provided id"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = 30

  source_path = "${path.module}/lambda_src"

  store_on_s3 = false
  environment_variables = {
    USER_STORAGE_TABLE = var.storage_table.name
    USER_POOL_ID       = var.user_pool_id
  }
}
resource "aws_iam_policy" "lambda_dyndb_update_item_userpool_get_user_unshare" {
  name        = "lambda_dyndb_update_item_userpool_get_user_unshare"
  description = "allows to update item from ${var.storage_table.arn} and to get user from user pool"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["dynamodb:UpdateItem"]
          Effect   = "Allow"
          Resource = "${var.storage_table.arn}"
        },
        {
          Action   = ["cognito-idp:ListUsers"]
          Effect   = "Allow"
          Resource = "${var.user_pool_arn}"
        },
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_dyndb_update_item_userpool_get_user_unshare" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = aws_iam_policy.lambda_dyndb_update_item_userpool_get_user_unshare.arn
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_unshareLambda" {
  statement_id  = "AllowApiGatewayInvokeUnshareLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.rest_api_execution_arn}/*/${local.unshare_doc_http_method}${var.parent_resource_path}/*"
}

