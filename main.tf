terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "website" {
  source = "./website"

  s3_origin_id  = "s3OriginId" #not clear
  bucket_prefix = "oxy-website-"
}

locals {
  ##to avoid collitions if we want to deploy multiple with a single aws account
  user_pool_domain = "oxy-user-pool-${random_string.id.result}"
  website          = "${module.api.endpoint_url}/web"
}

module "authorization" {
  source = "./authorization"

  region           = var.region
  website          = local.website
  user_pool_domain = local.user_pool_domain
}

module "storage" {
  source = "./storage"

  region           = var.region
  user_pool_domain = local.user_pool_domain

  #on_created_lambda_arn = module.lambdas.on_created_arn  
}

#module "lambdas" {
#  source = "./lambdas"
#  user_storage_table_name = module.database.table.name
#  user_storage_table_arn = module.database.table.arn
#}

module "database" {
  source = "./database"
}

resource "aws_iam_role_policy_attachment" "authenticated" {
  role       = module.authorization.authenticated_role_name
  policy_arn = module.storage.user_access_policy.arn
}

resource "random_string" "id" {
  length  = 6
  special = false
  upper   = false
}

module "api" {
  source = "./API"
  region = var.region
  storage_bucketName = module.storage.bucket.id
  storage_bucket_arn = module.storage.bucket.arn
  storage_table = module.database.table
  user_pool_arn = module.authorization.user_pool_arn 
  #4the workaround
  s3_website_endpoint = module.website.domain_name
}
