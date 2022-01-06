
resource "aws_api_gateway_method" "UnshareDoc" {
  rest_api_id   = var.rest_api_id
  resource_id   = var.resource_id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = var.authorizer_id
  request_parameters = {
    "method.request.path.id"                   = true
    "method.request.header.Content-Type"       = true
    "method.request.querystring.unshare_email" = true
  }
}
resource "aws_api_gateway_integration" "UnshareDoc" {
  rest_api_id             = var.rest_api_id
  resource_id             = var.resource_id
  http_method             = aws_api_gateway_method.UnshareDoc.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  timeout_milliseconds    = 29000
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = module.lambda_function.lambda_function_invoke_arn
}

resource "aws_api_gateway_method_response" "UnshareDoc_200" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.UnshareDoc.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Content-Type" = false
  }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "UnshareDoc_400" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.UnshareDoc.http_method
  status_code = 400
  response_parameters = {
    "method.response.header.Content-Type" = false
  }
  response_models = {
    "application/json" = "Empty"
  }
}

locals {
  unshare_doc_http_method = aws_api_gateway_method.UnshareDoc.http_method
}
