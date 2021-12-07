
resource "aws_api_gateway_method" "UploadDoc" {
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  resource_id   = aws_api_gateway_resource.DocPath.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.user_pool.id
  request_parameters = {
    "method.request.querystring.filename" = true
    "method.request.header.Content-Type"  = true
  }
}
resource "aws_api_gateway_integration" "UploadDoc" {
  rest_api_id             = aws_api_gateway_rest_api.OxyApi.id
  resource_id             = aws_api_gateway_resource.DocPath.id
  http_method             = aws_api_gateway_method.UploadDoc.http_method
  integration_http_method = aws_api_gateway_method.UploadDoc.http_method
  type                    = "AWS"
  timeout_milliseconds    = 29000

  # TODO: remove custom headers
  request_parameters = {
    "integration.request.path.user"                     = "context.authorizer.claims.cognito:username"
    "integration.request.path.company"                  = "context.authorizer.claims.custom:company"
    "integration.request.path.filename"                 = "context.requestId"
    "integration.request.header.x-amz-meta-user"        = "context.authorizer.claims.cognito:username"
    "integration.request.header.x-amz-meta-displayname" = "method.request.querystring.filename"
    "integration.request.header.Content-Type"           = "method.request.header.Content-Type"
  }
  credentials = aws_iam_role.APIGatewayS3FullAccess.arn
  uri         = "arn:aws:apigateway:${var.region}:s3:path/${var.storage_bucketName}/{company}/{user}/{filename}"
}

resource "aws_api_gateway_integration_response" "UploadDoc" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.DocPath.id
  http_method = aws_api_gateway_method.UploadDoc.http_method
  status_code = aws_api_gateway_method_response.UploadDoc_200.status_code
  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
  depends_on = [aws_api_gateway_method_response.UploadDoc_200]
}

resource "aws_api_gateway_method_response" "UploadDoc_200" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.DocPath.id
  http_method = aws_api_gateway_method.UploadDoc.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}


