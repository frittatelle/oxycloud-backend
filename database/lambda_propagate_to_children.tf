#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "propagate-to-children"
  description   = "Propagate deletion state to children"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  timeout = 30

  source_path = "${path.module}/lambda_src/propagate_to_children"

  store_on_s3 = false
  environment_variables = {
    USER_STORAGE_TABLE = local.table_name
  }

  allowed_triggers = {
    dynamodb = {
      service    = "dynamodb"
      principal  = "dynamodb.amazonaws.com"
      source_arn = local.table_arn
    }
  }

}

resource "aws_iam_policy" "lambda_propagate_to_children" {
  name        = "lambda_propagate_to_children"
  description = "allows to read Dynamo stream/records and update records"
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
          Resource = "${local.table_stream_arn}"
        },
        {
          Action = [
            "dynamodb:UpdateItem",
            "dynamodb:Query",
          ]
          Effect   = "Allow"
          Resource = "${local.table_arn}"
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_propagate_to_children" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = aws_iam_policy.lambda_propagate_to_children.arn
}

resource "aws_lambda_event_source_mapping" "propagate_to_children_dynamo_mapping" {
  event_source_arn  = local.table_stream_arn
  function_name     = module.lambda_function.lambda_function_arn
  starting_position = "LATEST"
  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["MODIFY"]
        dynamodb = {
          "OldImage" : {
            "is_doomed" : { "BOOL" : [false] },
            "is_folder" : { "BOOL" : [true] }
          },
          "NewImage" : {
            "is_doomed" : { "BOOL" : [true] },
            "is_folder" : { "BOOL" : [true] }
          },
        }
      })
    }
    filter {
      pattern = jsonencode({
        eventName = ["MODIFY"]
        dynamodb = {
          "OldImage" : {
            "is_deleted" : { "BOOL" : [false] },
            "is_folder" : { "BOOL" : [true] }
          },
          "NewImage" : {
            "is_deleted" : { "BOOL" : [true] },
            "is_folder" : { "BOOL" : [true] }
          },
        }
      })
    }
    filter {
      pattern = jsonencode({
        eventName = ["MODIFY"]
        dynamodb = {
          "OldImage" : {
            "is_deleted" : { "BOOL" : [true] },
            "is_folder" : { "BOOL" : [true] }
          },
          "NewImage" : {
            "is_deleted" : { "BOOL" : [false] },
            "is_folder" : { "BOOL" : [true] }
          },
        }
      })
    }
  }
}

