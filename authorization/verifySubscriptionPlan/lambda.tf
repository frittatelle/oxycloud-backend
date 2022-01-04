#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "verify-subscription-plan"
  description   = "MOCKUP - Verifies the subscription plan payment (Pre signup trigger)"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = 30

  source_path = "${path.module}/lambda_src"

  store_on_s3 = false
  allowed_triggers = {
    CognitoUserPool = {
      principal  = "cognito-idp.amazonaws.com"
      source_arn = var.user_pool_arn
    }
  }
}

resource "aws_lambda_permission" "cognito_presignup_trigger" {
  statement_id  = "AllowExecutionFromCognitoPreSignupTrigger"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = var.user_pool_arn
}
