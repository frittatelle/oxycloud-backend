# TODO: change scan to query to make dynamodb faster !
# TODO: change dynamodb attribute user_id the partition key!

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
  integration_http_method = aws_api_gateway_method.ListingDocs.http_method
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = "AWS"
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
  credentials = aws_iam_role.APIGatewayDynamoDBFullAccess.arn
  uri         = "arn:aws:apigateway:${var.region}:dynamodb:action/Scan"
  request_templates = {
    "application/json" = <<EOF
    {
    "TableName":"${var.storage_table.name}",
    "FilterExpression": "user_id = :user_id",
    "ExpressionAttributeValues": {
      ":user_id": {"S": "$context.authorizer.claims.cognito:username"}
    },
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
  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
  depends_on = [aws_api_gateway_method_response.ListingDocs_200]
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


