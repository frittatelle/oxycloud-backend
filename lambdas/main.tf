####################################################
# Lambda Function (building locally, storing on S3,
# set allowed triggers, set policies)
####################################################
#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "document-on_created"
  description   = "Callback on creation of a new object into the storage bucket"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true
  
  timeout       = 30

  source_path = "${path.module}/src/on_created"
# FIXME pls
#  policy_statements = {
#    dynamodb = {
#      effect    = "Allow",
#      actions   = [
#        "dynamodb:DescribeTable",
#        "dynamodb:Query",
#        "dynamodb:Scan",
#        "dynamodb:GetItem",
#        "dynamodb:PutItem",
#      ],
#      resources = ["*"]
#    }
#  }
  store_on_s3 = false
  environment_variables = {
    USER_STORAGE_TABLE = var.user_storage_table_name
  }
  #  attach_dead_letter_policy = true
  #  dead_letter_target_arn    = aws_sqs_queue.dlq.arn
}
resource "aws_iam_policy" "crud_dyndb" {
  name        = "CRUDDynamoDB"
  description = "CRUD permissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_crud-dyndb" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = aws_iam_policy.crud_dyndb.arn
}
