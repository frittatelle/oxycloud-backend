
resource "aws_api_gateway_method" "serviceMethod" {
  rest_api_id        = var.apigateway.id
  resource_id        = var.resource.id
  http_method        = var.http_method
  authorization      = var.authorizer.type
  authorizer_id      = var.authorizer.id
  request_parameters = var.request.parameters
}
resource "null_resource" "method-delay" {
  provisioner "local-exec" {
    command = "sleep 5"
  }
  triggers = {
    response = var.resource.id
  }
}

resource "aws_api_gateway_integration" "serviceMethod" {
    depends_on = [
    aws_api_gateway_method.serviceMethod,
    null_resource.method-delay
  ]

  rest_api_id             = var.apigateway.id
  resource_id             = var.resource.id
  http_method             = var.http_method
  integration_http_method = var.service.http_method
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = "AWS"
  timeout_milliseconds    = var.request.timeout_ms

  credentials = aws_iam_role.role.arn
  uri         = var.service.uri

  request_parameters = var.request.integration_parameters
  request_templates  = var.request.templates
}

resource "aws_api_gateway_integration_response" "serviceMethod" {
  #https://github.com/hashicorp/terraform-provider-aws/issues/4001
  depends_on = [
    aws_api_gateway_method.serviceMethod,
    aws_api_gateway_integration.serviceMethod,
    aws_api_gateway_method_response.serviceMethod,
    null_resource.method-delay
  ]

  for_each            = var.responses

  rest_api_id         = var.apigateway.id
  resource_id         = var.resource.id
  http_method         = var.http_method
  status_code         = each.value.integration_status_code
  response_parameters = each.value.integration_parameters
  response_templates  = each.value.integration_templates
  selection_pattern   = each.value.integration_selection_pattern
  content_handling    = each.value.integration_content_handling
}

resource "aws_api_gateway_method_response" "serviceMethod" {
  depends_on = [
    aws_api_gateway_method.serviceMethod
  ]

  for_each            = var.responses

  rest_api_id         = var.apigateway.id
  resource_id         = var.resource.id
  http_method         = var.http_method
  status_code         = each.value.status_code
  response_parameters = each.value.parameters
  response_models     = each.value.models
}


resource "aws_iam_role_policy_attachment" "attach-policy" {
  role = aws_iam_role.role.name
  policy_arn = var.service.policy_arn
}

resource "aws_iam_role" "role" {
  name = "APIGateway${title(var.name)}ServiceMethod"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}