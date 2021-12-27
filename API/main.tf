resource "aws_api_gateway_rest_api" "OxyApi" {
  name               = "OxyApi"
  binary_media_types = ["*/*"]
}

resource "aws_api_gateway_authorizer" "user_pool" {
  name          = "OxyApi-user_pool-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  provider_arns = [var.user_pool_arn]
}

resource "aws_api_gateway_resource" "SharePath" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  parent_id   = aws_api_gateway_rest_api.OxyApi.root_resource_id
  path_part   = "share"
}

resource "aws_api_gateway_resource" "ShareID" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  parent_id   = aws_api_gateway_resource.SharePath.id
  path_part   = "{id}"
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

resource "aws_api_gateway_resource" "UserPath" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  parent_id   = aws_api_gateway_rest_api.OxyApi.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "UserID" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  parent_id   = aws_api_gateway_resource.UserPath.id
  path_part   = "{id}"
}

resource "aws_iam_role" "APIGatewayS3FullAccess" {
  name = "APIGatewayS3FullAccessRole"
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

resource "aws_iam_role_policy_attachment" "attach-policy" {
  role = aws_iam_role.APIGatewayS3FullAccess.name
  #default by aws 
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role" "APIGatewayDynamoDBFullAccess" {
  name = "APIGatewayDynamoDBFullAccessRole"
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

resource "aws_iam_role_policy_attachment" "attach-policy-ddb" {
  role = aws_iam_role.APIGatewayDynamoDBFullAccess.name
  #default by aws 
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role" "APIGatewayCognitoIDPListUsers" {
  name = "APIGatewayCognitoIDPListUsersRole"
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

resource "aws_iam_policy" "cidp_listUsers" {
  name        = "cognito-idp_listUsers"
  description = "Allows listUsers action on ${var.user_pool_id} user_pool"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cognito-idp:ListUsers"
      ],
      "Effect": "Allow",
      "Resource": "${var.user_pool_arn}"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "attach-policy-cidp-listusers" {
  role       = aws_iam_role.APIGatewayCognitoIDPListUsers.name
  policy_arn = aws_iam_policy.cidp_listUsers.arn
}


module "upload_docs_method" {
  source                 = "./uploadFile/"
  rest_api_id            = aws_api_gateway_rest_api.OxyApi.id
  resource_id            = aws_api_gateway_resource.DocPath.id
  region                 = var.region
  storage_bucket_id      = var.storage_bucketName
  storage_bucket_arn     = var.storage_bucket_arn
  storage_table          = var.storage_table
  authorizer_id          = aws_api_gateway_authorizer.user_pool.id
  rest_api_execution_arn = aws_api_gateway_rest_api.OxyApi.execution_arn
  parent_resource_path   = aws_api_gateway_resource.DocPath.path
}

module "download_docs_method" {
  source                 = "./downloadFile/"
  rest_api_execution_arn = aws_api_gateway_rest_api.OxyApi.execution_arn
  rest_api_id            = aws_api_gateway_rest_api.OxyApi.id
  resource_id            = aws_api_gateway_resource.DocID.id
  parent_resource_path   = aws_api_gateway_resource.DocPath.path
  region                 = var.region
  storage_bucket_id      = var.storage_bucketName
  storage_bucket_arn     = var.storage_bucket_arn
  storage_table          = var.storage_table
  authorizer_id          = aws_api_gateway_authorizer.user_pool.id
}

module "share_docs_method" {
  source                 = "./shareFile/"
  rest_api_execution_arn = aws_api_gateway_rest_api.OxyApi.execution_arn
  rest_api_id            = aws_api_gateway_rest_api.OxyApi.id
  resource_id            = aws_api_gateway_resource.ShareID.id
  parent_resource_path   = aws_api_gateway_resource.SharePath.path
  region                 = var.region
  storage_bucket_id      = var.storage_bucketName
  storage_bucket_arn     = var.storage_bucket_arn
  storage_table          = var.storage_table
  authorizer_id          = aws_api_gateway_authorizer.user_pool.id
  user_pool_arn          = var.user_pool_arn
  user_pool_id           = var.user_pool_id
}

module "unshare_docs_method" {
  source                 = "./unshareFile/"
  rest_api_execution_arn = aws_api_gateway_rest_api.OxyApi.execution_arn
  rest_api_id            = aws_api_gateway_rest_api.OxyApi.id
  resource_id            = aws_api_gateway_resource.ShareID.id
  parent_resource_path   = aws_api_gateway_resource.SharePath.path
  region                 = var.region
  storage_bucket_id      = var.storage_bucketName
  storage_bucket_arn     = var.storage_bucket_arn
  storage_table          = var.storage_table
  authorizer_id          = aws_api_gateway_authorizer.user_pool.id
  user_pool_arn          = var.user_pool_arn
  user_pool_id           = var.user_pool_id
}

module "doom_docs_lambda" {
  source                   = "./doomFile/"
  region                   = var.region
  storage_bucket_id        = var.storage_bucketName
  storage_bucket_arn       = var.storage_bucket_arn
  storage_table            = var.storage_table
  storage_table_arn        = var.storage_table_arn
  storage_table_stream_arn = var.storage_table_stream_arn
}

resource "aws_api_gateway_deployment" "OxyApi" {
  rest_api_id       = aws_api_gateway_rest_api.OxyApi.id
  stage_description = "Deployed at ${timestamp()}"

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.OxyApi.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.ProxyPath,
    aws_api_gateway_method.IndexPath,
    aws_api_gateway_integration.ProxyPath,
    aws_api_gateway_integration.IndexPath,
    module.upload_docs_method,
    module.download_docs_method,
    module.share_docs_method,
    module.unshare_docs_method
  ]
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.OxyApi.id
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  stage_name    = "dev"
}

resource "aws_api_gateway_domain_name" "OxyApi_domain" {
  certificate_arn = var.certificate_arn
  domain_name     = "api.oxycloud.space"
}

resource "aws_api_gateway_base_path_mapping" "dev" {
  api_id      = aws_api_gateway_rest_api.OxyApi.id
  domain_name = aws_api_gateway_domain_name.OxyApi_domain.domain_name
  stage_name  = aws_api_gateway_stage.dev.stage_name
}
