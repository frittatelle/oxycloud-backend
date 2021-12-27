module "downloadFile"{
    source = "../modules/restapi_lambda_method"
    lambda = {
        name                  = "download-file"
        description           = "Download file with provided id"
        policy_arn            = aws_iam_policy.downloadFile.arn
        timeout               = 30
        source_path           = "${path.module}/src/downloadFile"
        environment_variables = {
            USER_STORAGE_TABLE = var.storage_table.name
            USER_STORAGE_BUCKET = var.storage_bucketName
        }
    }
    http_method        = "GET"

    apigateway = {
        arn = aws_api_gateway_rest_api.OxyApi.execution_arn
        id  = aws_api_gateway_rest_api.OxyApi.id
    }


    authorizer = {
        type = "COGNITO_USER_POOLS"
        id   = aws_api_gateway_authorizer.user_pool.id
    }

    resource = aws_api_gateway_resource.DocID

    request = {
        parameters = {
          "method.request.path.id"             = true
          "method.request.header.Content-Type" = true
        }
        timeout_ms = 29000
    }

    responses = {
        "ok" = {
            integration_parameters        = {}
            integration_templates         = {
                "application/json" = ""
            }
            integration_selection_pattern = null
            integration_status_code       = 200
            integration_content_handling  = null

            models      = {
                "application/json" = "Empty"
            }
            parameters  = {
                "method.response.header.Content-Type" = false
            }
            status_code = 200
        }
    }

    depends_on = [
      aws_api_gateway_rest_api.OxyApi
    ]
}

resource "aws_iam_policy" "downloadFile" {
  name        = "lambda_downloadFile"
  description = "allows to get item.path from ${var.storage_table.arn}"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["dynamodb:GetItem"]
          Effect   = "Allow"
          Resource = "${var.storage_table.arn}"
        },
        {
          Action   = ["s3:GetObject"]
          Effect   = "Allow"
          Resource = "${var.storage_bucket_arn}/*"
        },
      ]
    }
  )
}