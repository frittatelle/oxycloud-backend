
resource "aws_api_gateway_method" "UploadDoc" {
  rest_api_id   = var.rest_api_id
  resource_id   = var.resource_id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = var.authorizer_id
  request_parameters = {
    "method.request.querystring.filename" = true
    "method.request.header.Content-Type"  = true
  }
}
resource "aws_api_gateway_integration" "UploadDoc" {
  rest_api_id             = var.rest_api_id
  resource_id             = var.resource_id
  http_method             = aws_api_gateway_method.UploadDoc.http_method
  integration_http_method = aws_api_gateway_method.UploadDoc.http_method
  type                    = "AWS_PROXY"
  timeout_milliseconds    = 29000
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = module.lambda_method.lambda_function_invoke_arn
}

resource "aws_api_gateway_integration_response" "UploadDoc" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.UploadDoc.http_method
  status_code = aws_api_gateway_method_response.UploadDoc_200.status_code
  response_parameters = {}
  response_templates = {
    "application/json" = ""
  }
  depends_on = [aws_api_gateway_integration.UploadDoc]
}

resource "aws_api_gateway_method_response" "UploadDoc_200" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.UploadDoc.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Content-Type" = false 
  }
  response_models = {
    "application/json" = "Empty"
  }
}

