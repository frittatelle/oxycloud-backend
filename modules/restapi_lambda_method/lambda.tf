#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.28.0"

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
  allowed_triggers = {
    ApiGatewayRule = {
      principal  = "apigateway.amazonaws.com"                   #replace {proxy_whatever} with a *
      source_arn = "${var.apigateway.arn}/*/${var.http_method}${replace(var.resource.path, "/\\{\\w+\\}/", "*")}"
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = var.lambda.policy_arn
}
