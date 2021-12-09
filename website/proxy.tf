#MEGA WORKAROUND
# cognito user pool login requires an https redirection endpoint
# simple s3 website doesn't support https
# not being able to use cloud front
# => proxy s3 website trough apigateway

resource "aws_api_gateway_rest_api" "website" {
  name = "website-proxy"
  binary_media_types = ["*/*"]
}

resource "aws_api_gateway_deployment" "website" {
  rest_api_id = aws_api_gateway_rest_api.website.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.website.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
   aws_api_gateway_method.ProxyPath, 
   aws_api_gateway_method.IndexPath, 
  ]
}

resource "aws_api_gateway_stage" "web" {
  deployment_id = aws_api_gateway_deployment.website.id
  rest_api_id   = aws_api_gateway_rest_api.website.id
  stage_name    = "web"
}

resource "aws_api_gateway_resource" "ProxyPath" {
  rest_api_id = aws_api_gateway_rest_api.website.id
  parent_id   = aws_api_gateway_rest_api.website.root_resource_id
  path_part   = "{proxy+}"
}


resource "aws_api_gateway_method" "ProxyPath" {
  rest_api_id   = aws_api_gateway_rest_api.website.id
  resource_id   = aws_api_gateway_resource.ProxyPath.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
     "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "ProxyPath" {
  rest_api_id             = aws_api_gateway_rest_api.website.id
  resource_id             = aws_api_gateway_resource.ProxyPath.id
  http_method             = "ANY" 
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  timeout_milliseconds    = 29000
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  uri = "http://${aws_s3_bucket.hosting.website_endpoint}/{proxy}"
}

resource "aws_api_gateway_method" "IndexPath" {
  rest_api_id   = aws_api_gateway_rest_api.website.id
  resource_id   = aws_api_gateway_rest_api.website.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "IndexPath" {
  rest_api_id             = aws_api_gateway_rest_api.website.id
  resource_id             = aws_api_gateway_rest_api.website.root_resource_id
  http_method             = "ANY"
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  timeout_milliseconds    = 29000

  uri = "http://${aws_s3_bucket.hosting.website_endpoint}/index.html"
}

