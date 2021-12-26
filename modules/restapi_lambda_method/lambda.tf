#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = local.lambda.name  
  description   = local.lambda.description 
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = 30

  source_path = "${path.module}/lambda_src"

  store_on_s3 = false
  environment_variables = var.lambda.environment_variables
}

resource "aws_iam_role_policy_attachment" "lambda_crud_dyndb" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = var.lambda.policy.arn
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_downloadLambda" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = local.source_arn 
}

