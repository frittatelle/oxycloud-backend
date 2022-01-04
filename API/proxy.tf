#MEGA WORKAROUND
# cognito user pool login requires an https redirection endpoint
# simple s3.OxyApi.doesn't support https
# not being able to use cloud front
# => proxy s3.OxyApi.trough apigateway
# MEGA SUB-WORKAROUND
# CORS give some truble 
# put the.OxyApi.proxy under the same domain of the api

resource "aws_api_gateway_resource" "IndexPath" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  parent_id   = aws_api_gateway_rest_api.OxyApi.root_resource_id
  path_part   = "web"
}


resource "aws_api_gateway_resource" "ProxyPath" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  parent_id   = aws_api_gateway_resource.IndexPath.id
  path_part   = "{proxy+}"
}


resource "aws_api_gateway_method" "ProxyPath" {
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  resource_id   = aws_api_gateway_resource.ProxyPath.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
     "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "ProxyPath" {
  rest_api_id             = aws_api_gateway_rest_api.OxyApi.id
  resource_id             = aws_api_gateway_resource.ProxyPath.id
  http_method             = "ANY" 
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  timeout_milliseconds    = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  uri = "http://${var.s3_website_endpoint}/{proxy}"
}

resource "aws_api_gateway_method" "IndexPath" {
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  resource_id   = aws_api_gateway_resource.IndexPath.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "IndexPath" {
  rest_api_id             = aws_api_gateway_rest_api.OxyApi.id
  resource_id             = aws_api_gateway_resource.IndexPath.id
  http_method             = "ANY"
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  timeout_milliseconds    = 29000

  uri = "http://${var.s3_website_endpoint}/index.html"
}

