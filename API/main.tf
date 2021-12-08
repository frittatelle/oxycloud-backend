provider "aws" {
  region  = var.region
}

resource "aws_api_gateway_rest_api" "OxyApi" {
  name = "OxyApi"
  binary_media_types = ["*/*"]
}

resource "aws_api_gateway_authorizer" "user_pool" {
  name = "OxyApi-user_pool-authorizer"
  type = "COGNITO_USER_POOLS"
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  provider_arns = [var.user_pool_arn]
}

resource "aws_api_gateway_resource" "DocPath" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  parent_id   = aws_api_gateway_rest_api.OxyApi.root_resource_id
  path_part   = "docs"
}

resource "aws_api_gateway_resource" "DocID" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  parent_id   = aws_api_gateway_resource.DocPath.id
  path_part   = "{id}"

}
resource "aws_iam_role" "APIGatewayS3FullAccess" {
  name = "APIGatewayS3FullAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement =  [
      {
        Sid = ""
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "attach-policy" {
  role = aws_iam_role.APIGatewayS3FullAccess.name
  #default by aws 
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role" "APIGatewayDynamoDBFullAccess" {
  name = "APIGatewayDynamoDBFullAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement =  [
      {
        Sid = ""
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach-policy-ddb" {
  role = aws_iam_role.APIGatewayS3FullAccess.name
  #default by aws 
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

module "upload_docs_method" {
  source = "./upload/"
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.DocID.id
  region      = var.region
  storage_bucket_id = var.storage_bucketName
  storage_bucket_arn = var.storage_bucket_arn
  storage_table = var.storage_table
  authorizer_id = aws_api_gateway_authorizer.user_pool.id
}

