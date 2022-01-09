module "listDocs" {
  source      = "../modules/restapi_service_method"
  http_method = "GET"
  name        = "listDocs"
  service = {
    uri         = "arn:aws:apigateway:${var.region}:dynamodb:action/Query"
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

  resource = aws_api_gateway_resource.DocPath

  request = {
    parameters = {
      "method.request.querystring.deleted" = true
      "method.request.header.Content-Type" = true
    }
    integration_parameters = {
      "integration.request.header.Content-Type" = "method.request.header.Content-Type"
    }
    timeout_ms = 29000
    templates = {
      "application/json" = local.docs_GET_request_template
    }
  }

  responses = ({
    ok = {
      integration_parameters = {
        "method.response.header.Content-Type" = "integration.response.header.Content-Type"
      }
      integration_templates = {
        "application/json" = local.docs_GET_ok_response_template
      }
      integration_selection_pattern = "2\\d{2}"
      integration_status_code       = 200
      integration_content_handling  = "CONVERT_TO_TEXT"

      models = {
        "application/json" = "Error"
      }
      parameters = {
        "method.response.header.Content-Type" = true
      }
      status_code = 200
    }
    ko_user = {
      integration_parameters = {
        "method.response.header.Content-Type" = "integration.response.header.Content-Type"
      }
      integration_templates = null
      integration_selection_pattern = "4\\d{2}"
      integration_status_code       = 400
      integration_content_handling  = null

      models = {
        "application/json" = "Error"
      }
      parameters = {
        "method.response.header.Content-Type" = true
      }
      status_code = 400
    }

    ko_server = {
        integration_parameters = {
          "method.response.header.Content-Type" = "integration.response.header.Content-Type"
        }
        integration_templates = null
        integration_selection_pattern = "5\\d{2}"
        integration_status_code       = 500
        integration_content_handling  = null

        models = {
          "application/json" = "Error"
        }
        parameters = {
          "method.response.header.Content-Type" = true
        }
        status_code = 500
      }
    })
}

locals {
  docs_GET_request_template = <<EOF
    #set($user_id = $context.authorizer.claims['cognito:username'])
    #set($deleted = $method.request.querystring.deleted)
    #if(!$deleted || $deleted.equals(""))
      #set($deleted = false)
    #end
    #set($folder  = $method.request.querystring.folder)
    {
      "TableName":"${var.storage_table.name}",
      "KeyConditionExpression":"user_id = :user_id",
      "FilterExpression":"folder = :folder AND is_deleted = :deleted AND is_doomed = :doomed",
      "ExpressionAttributeValues": {
        ":user_id": { "S": "$user_id"},
        ":deleted": { "BOOL": $deleted},
        ":folder":  { "S": "$folder"},
        ":doomed": { "BOOL": false}
      },
      "ReturnConsumedCapacity": "TOTAL"
    }
  EOF

  docs_GET_ok_response_template = <<EOF
#set($inputRoot = $util.parseJson($util.base64Decode($input.body)))

#set($files=[])
#foreach($it in $inputRoot.Items)
#if(!$it.is_folder.BOOL)
#set($bar = $files.add($it))
#end
#end

#set($folders=[])
#foreach($it in $inputRoot.Items)
#if($it.is_folder.BOOL)
#set($bar = $folders.add($it))
#end
#end
{
 "files": [
    #foreach($it in $files)
    {
    "id":"$it.file_id.S",
    "size":$it.size.N,
    "owner":"$it.user_id.S",
    "last_edit":"$it.time.S",
    "etag":"$it.eTag.S",
    "folder":"$it.folder.S",
    "shared_with":[#foreach($u in $it.shared_with.SS)
        "$u"#if($foreach.hasNext),#end
    #end],
    "name":"$it.display_name.S"
    }#if($foreach.hasNext),#end
    #end
  ],
 "folders": [
    #foreach($it in $folders)
    {
    "id":"$it.file_id.S",
    "owner":"$it.user_id.S",
    "name":"$it.display_name.S"
    }#if($foreach.hasNext),#end
    #end
  ]

}
    EOF
}