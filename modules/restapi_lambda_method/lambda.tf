#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = var.lambda.name
  description   = var.lambda.description
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = var.lambda.timeout

  source_path = var.lambda.source_path

  store_on_s3           = false
  environment_variables = var.lambda.environment_variables
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = var.lambda.policy_arn
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_Lambda" {
  statement_id  = "AllowApiGatewayLambdaInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.apigateway.arn
}
