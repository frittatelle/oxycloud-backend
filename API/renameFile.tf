
resource "aws_api_gateway_method" "RenameDoc" {
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  resource_id   = aws_api_gateway_resource.DocID.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.user_pool.id
  request_parameters = {
    "method.request.querystring.filename" = true
    "method.request.header.Content-Type" = true
  }
}
resource "aws_api_gateway_integration" "RenameDoc" {
  rest_api_id             = aws_api_gateway_rest_api.OxyApi.id
  resource_id             = aws_api_gateway_resource.DocID.id
  http_method             = aws_api_gateway_method.RenameDoc.http_method
  integration_http_method = aws_api_gateway_method.RenameDoc.http_method
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = "AWS"
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
  credentials = aws_iam_role.APIGatewayDynamoDBFullAccess.arn
  #TODO remove hardcode tablename and region
  uri = "arn:aws:apigateway:us-east-1:dynamodb:action/UpdateItem"
  request_templates = {
    "application/json" = <<EOF
  #set($user_id = $context.authorizer.claims['cognito:username'])
  {
    "TableName":"oxycloud",
    "Key":{
        "file_id":{
            "S":"$method.request.path.id"
        },
        "user_id":{
          "S":"$user_id"
        }
    },
    "UpdateExpression": "set display_name = :filename",
    "ConditionExpression": "file_id = :file_id AND user_id = :user_id",
    "ExpressionAttributeValues": {
        ":filename": {"S": "$method.request.querystring.filename"},
        ":file_id": {"S: "$method.request.path.file_id"},
        ":user_id": {"S: "$user_id"}
    },
  }
    EOF
  }
}

resource "aws_api_gateway_integration_response" "RenameDoc" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.DocID.id
  http_method = aws_api_gateway_method.RenameDoc.http_method
  status_code = aws_api_gateway_method_response.RenameDoc_200.status_code
  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
  depends_on = [aws_api_gateway_method_response.RenameDoc_200]
}

resource "aws_api_gateway_method_response" "RenameDoc_200" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.DocID.id
  http_method = aws_api_gateway_method.RenameDoc.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}


