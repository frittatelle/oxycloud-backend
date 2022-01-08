module "listShared" {
  source      = "../modules/restapi_service_method"
  http_method = "GET"
  name        = "listShared"
  service = {
    uri         = "arn:aws:apigateway:${var.region}:dynamodb:action/Scan"
    policy_arn  = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    http_method = "POST"
  }

  apigateway = {
    arn = aws_api_gateway_rest_api.OxyApi.execution_arn
    id  = aws_api_gateway_rest_api.OxyApi.id
  }

  authorizer = {
    type = "COGNITO_USER_POOLS"
    id   = aws_api_gateway_authorizer.user_pool.id
  }

  resource = aws_api_gateway_resource.SharePath

  request = {
    parameters = {
      "method.request.header.Content-Type" = true
    }
    integration_parameters = {
      "integration.request.header.Content-Type" = "method.request.header.Content-Type"
    }
    timeout_ms = 29000
    templates = {
      "application/json" =  <<EOF
    #set($user_id = $context.authorizer.claims['cognito:username'])
    {
        "TableName":"${var.storage_table.name}",
        "FilterExpression": "is_doomed = :doom AND contains(shared_with, :user_id)",
        "ExpressionAttributeValues": {
          ":user_id": { "S": "$user_id"},
          ":doom":{"BOOL":"false"}
        },
        "ReturnConsumedCapacity": "TOTAL"
    }
    EOF
  }
  }
  responses = {
    "ok" = {
      integration_parameters = {
        "method.response.header.Content-Type" = "integration.response.header.Content-Type"
      }
      integration_templates  = {
        "application/json"= local.listshared_response_template
      }
      integration_selection_pattern = "2\\d{2}"
      integration_status_code       = 200
      integration_content_handling  = "CONVERT_TO_TEXT"

      models = {
        "application/json" = "Empty"
      }
      parameters = {
        "method.response.header.Content-Type" = true
      }
      status_code = 200
    }
  }
}

locals {
  listshared_response_template = <<EOF
    #set($inputRoot = $util.parseJson($util.base64Decode($input.body)))
    {
       "files": [
          #foreach($it in $inputRoot.Items) {
          "id":"$it.file_id.S",
          "size":$it.size.N,
          "owner":"$it.user_id.S",
          "last_edit":"$it.time.S",
          "etag":"$it.eTag.S",
          "name":"$it.display_name.S"
          }#if($foreach.hasNext),#end
          #end
        ],
      ## folders will not propably handled for sharing
      "folders":[]
    }
    EOF
}
