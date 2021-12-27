module "unshareFile" {
  source = "../modules/restapi_lambda_method"
  lambda = {
    name        = "unshare-file"
    description = "Unshare file with provided id"
    policy_arn  = aws_iam_policy.downloadFile.arn
    timeout     = 30
    source_path = "${path.module}/src/unshareFile"
    environment_variables = {
      USER_STORAGE_TABLE = var.storage_table.name
      USER_POOL_ID       = var.user_pool_id
    }
  }
  http_method = "DELETE"

  apigateway = {
    arn = aws_api_gateway_rest_api.OxyApi.execution_arn
    id  = aws_api_gateway_rest_api.OxyApi.id
  }


  authorizer = {
    type = "COGNITO_USER_POOLS"
    id   = aws_api_gateway_authorizer.user_pool.id
  }

  resource = aws_api_gateway_resource.ShareID

  request = {
    parameters = {
      "method.request.path.id"                   = true
      "method.request.header.Content-Type"       = true
      "method.request.querystring.unshare_email" = true
    }
    timeout_ms = 29000
  }

  responses = {
    "ok" = {
      integration_parameters = {}
      integration_templates = {
        "application/json" = ""
      }
      integration_selection_pattern = null
      integration_status_code       = 200
      integration_content_handling  = null

      models = {
        "application/json" = "Empty"
      }
      parameters = {
        "method.response.header.Content-Type" = false
      }
      status_code = 200
    }
  }

  depends_on = [
    aws_api_gateway_rest_api.OxyApi
  ]
}

resource "aws_iam_policy" "unshareFile" {
  name        = "lambda_dyndb_update_item_userpool_get_user_unshare"
  description = "allows to update item from ${var.storage_table.arn} and to get user from user pool"
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["dynamodb:UpdateItem"]
          Effect   = "Allow"
          Resource = "${var.storage_table.arn}"
        },
        {
          Action   = ["cognito-idp:ListUsers"]
          Effect   = "Allow"
          Resource = "${var.user_pool_arn}"
        },
      ]
    }
  )
}