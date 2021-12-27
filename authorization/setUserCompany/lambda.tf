#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "set-user-company"
  description   = "Sets user company in congito user pool (Post confirmation trigger)"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = 30

  source_path = "${path.module}/lambda_src"

  store_on_s3 = false

}
resource "aws_iam_policy" "lambda_update_user_attributes" {
  name        = "lambda_update_user_attributes"
  description = "allows lambda to update user attributes"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["cognito-idp:AdminUpdateUserAttributes"]
          Effect   = "Allow"
          Resource = "${var.user_pool_arn}"
        },

      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_update_user_attributes" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = aws_iam_policy.lambda_update_user_attributes.arn
}