resource "aws_api_gateway_method" "ListingDocs" {
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  resource_id   = aws_api_gateway_resource.DocPath.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.user_pool.id
  request_parameters = {
    "method.request.header.Content-Type" = true
  }

}

resource "aws_api_gateway_integration" "ListingDocs" {
  rest_api_id             = aws_api_gateway_rest_api.OxyApi.id
  resource_id             = aws_api_gateway_resource.DocPath.id
  http_method             = aws_api_gateway_method.ListingDocs.http_method
  integration_http_method = "POST"
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = "AWS"
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
  credentials = aws_iam_role.APIGatewayDynamoDBFullAccess.arn
  uri         = "arn:aws:apigateway:${var.region}:dynamodb:action/Query"
  request_templates = {
    "application/json" = <<EOF
    #set($user_id = $context.authorizer.claims['cognito:username'])
    {
        "TableName":"${var.storage_table.name}",
        "KeyConditionExpression":"user_id = :user_id",
            "ExpressionAttributeValues": {":user_id": { "S": "$user_id"}},
        "ReturnConsumedCapacity": "TOTAL"
    }
    EOF
  }
}

resource "aws_api_gateway_integration_response" "ListingDocs" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.DocPath.id
  http_method = aws_api_gateway_method.ListingDocs.http_method
  status_code = aws_api_gateway_method_response.ListingDocs_200.status_code
  content_handling = "CONVERT_TO_TEXT"
  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
  response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $util.parseJson($util.base64Decode($input.body)))
    {
       "files": [
          #foreach($it in $inputRoot.Items) {
          "size":"$it.size.N",
          "owner":"$it.user_id.S",
          "last_edit":"$it.time.S",
          "etag":"$it.eTag.S",
          "path":"$it.display_name.S"
          }#if($foreach.hasNext),#end
          #end
        ]
    }
    EOF
  }
  depends_on = [aws_api_gateway_integration.ListingDocs]
}

resource "aws_api_gateway_method_response" "ListingDocs_200" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.DocPath.id
  http_method = aws_api_gateway_method.ListingDocs.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}


