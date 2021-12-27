
resource "aws_api_gateway_method" "lambdaMethod" {
  rest_api_id        = var.apigateway.id
  resource_id        = var.resource.id
  http_method        = var.http_method
  authorization      = var.authorizer.type
  authorizer_id      = var.authorizer.id
  request_parameters = var.request.parameters
}
resource "aws_api_gateway_integration" "lambdaMethod" {
  rest_api_id             = var.apigateway.id
  resource_id             = var.resource.id
  http_method             = var.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  timeout_milliseconds    = var.request.timeout_ms
  passthrough_behavior    = "WHEN_NO_MATCH"
  uri                     = module.lambda_function.lambda_function_invoke_arn
}

resource "aws_api_gateway_integration_response" "lambdaMethod" {
  for_each            = var.responses
  rest_api_id         = var.apigateway.id
  resource_id         = var.resource.id
  http_method         = var.http_method
  status_code         = each.value.integration_status_code
  response_parameters = each.value.integration_parameters
  response_templates  = each.value.integration_templates
  selection_pattern   = each.value.integration_selection_pattern
  content_handling    = each.value.integration_content_handling

  depends_on = [aws_api_gateway_integration.lambdaMethod]
}

resource "aws_api_gateway_method_response" "lambdaMethod" {
  for_each            = var.responses
  rest_api_id         = var.apigateway.id
  resource_id         = var.resource.id
  http_method         = var.http_method
  status_code         = each.value.status_code
  response_parameters = each.value.parameters
  response_models     = each.value.models
}
