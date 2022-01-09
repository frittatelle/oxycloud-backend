module "uploadFile" {
  source = "../modules/restapi_lambda_method"
  lambda = {
    name        = "upload-file-method"
    description = "Generate presigned upload url"
    policy_arn  = aws_iam_policy.uploadFile.arn
    timeout     = 30
    source_path = "${path.module}/src/uploadFile"
    environment_variables = {
      USER_STORAGE_TABLE  = var.storage_table.name
      USER_STORAGE_BUCKET = var.storage_bucketName
      USERS_TABLE         = var.users_table.name
    }
  }
  http_method = "PUT"

  apigateway = {
    arn = aws_api_gateway_rest_api.OxyApi.execution_arn
    id  = aws_api_gateway_rest_api.OxyApi.id
  }


  authorizer = {
    type = "COGNITO_USER_POOLS"
    id   = aws_api_gateway_authorizer.user_pool.id
  }

  resource = aws_api_gateway_resource.DocPath

  request = {
    parameters = {
      "method.request.path.id"             = true
      "method.request.header.Content-Type" = true
    }
    timeout_ms = 29000
  }

  depends_on = [
    aws_api_gateway_rest_api.OxyApi
  ]
}

resource "aws_iam_policy" "uploadFile" {
  name        = "lambda_uploadFile"
  description = "allows to put object into ${var.storage_bucket_arn} and items into Dynamo"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:PutItem"]
        Effect   = "Allow"
        Resource = "${var.storage_table.arn}"
      },
      {
        Action   = ["dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = "${var.users_table.arn}"
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "${var.storage_bucket_arn}/*"
      },
    ]
    }
  )
}