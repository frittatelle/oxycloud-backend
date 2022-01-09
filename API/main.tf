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

module "upload_docs_trigger" {
  source             = "./uploadFile/"
  storage_bucket_id  = var.storage_bucketName
  storage_bucket_arn = var.storage_bucket_arn
  storage_table      = var.storage_table
  users_table        = var.users_table
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
    module.listShared,
    module.getUser,
    module.searchUsers,
    module.deleteDoc,
    module.listDocs,
    module.uploadFile,
    module.downloadFile,
    module.shareFile,
    module.unshareFile
  ]
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.OxyApi.id
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  stage_name    = "dev"
}

resource "aws_api_gateway_method_settings" "dev" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "ERROR"
  }
}
