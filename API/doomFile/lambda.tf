#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "doom-file"
  description   = "Permanently delete (doom) file with provided id"
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

  allowed_triggers = {
    dynamodb = {
      service    = "dynamodb"
      principal  = "dynamodb.amazonaws.com"
      source_arn = var.storage_table_arn
    }
  }

}
resource "aws_iam_policy" "lambda_delete_object" {
  name        = "lambda_delete_object"
  description = "allows S3 object deletion from lambda"
  depends_on = [
    module.lambda_function.lambda_role_name
  ]
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:DescribeStream",
            "dynamodb:ListShards",
            "dynamodb:ListStreams"
          ]
          Effect   = "Allow"
          Resource = "${var.storage_table_stream_arn}"
        },
        {
          Action   = ["s3:DeleteObject"]
          Effect   = "Allow"
          Resource = "${var.storage_bucket_arn}/*"
        },

      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_delete_object" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = aws_iam_policy.lambda_delete_object.arn
}

resource "aws_lambda_event_source_mapping" "doom_lambda_dynamo_mapping" {
  event_source_arn  = var.storage_table_stream_arn
  function_name     = module.lambda_function.lambda_function_arn
  starting_position = "LATEST"
  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["MODIFY"]
        dynamodb  = { "NewImage" : { "is_doomed" : { "BOOL" : [true] } } }
      })
    }
  }
}
