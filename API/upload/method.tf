
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
  credentials = aws_iam_role.APIGateway_storage_api_upload.arn
  uri         = "arn:aws:apigateway:${var.region}:s3:path/${var.storage_bucket_id}/{company}/{user}/{filename}"
}

resource "aws_api_gateway_integration_response" "UploadDoc" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.UploadDoc.http_method
  status_code = aws_api_gateway_method_response.UploadDoc_200.status_code
  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
  depends_on = [aws_api_gateway_integration.UploadDoc]
}

resource "aws_api_gateway_method_response" "UploadDoc_200" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.UploadDoc.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_iam_role" "APIGateway_storage_api_upload" {
  name = "APIGateway-storage-api-upload"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = ""
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
  }, ] })

}

resource "aws_iam_policy" "policy" {
  name        = "upload-to-${var.storage_bucket_id}-policy"
  description = "A policy to put objects into ${var.storage_bucket_id}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "s3:PutObject",
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      Effect   = "Allow",
      Resource = "${var.storage_bucket_arn}/*"
  }, ] })
}

resource "aws_iam_role_policy_attachment" "attach-policy_agw-s3_upload" {
  role       = aws_iam_role.APIGateway_storage_api_upload.name
  policy_arn = aws_iam_policy.policy.arn
}


