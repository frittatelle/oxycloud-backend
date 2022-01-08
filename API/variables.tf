variable "user_pool_arn" {

}

variable "user_pool_id" {

}

variable "storage_bucketName" {

}

variable "storage_table" {
}

variable "storage_table_arn" {

}

variable "storage_table_stream_arn" {

}

variable "region" {

}
variable "storage_bucket_arn" {}

variable "s3_website_endpoint" {}

locals {
  user_pool = {
    arn = var.user_pool_arn
    id  = var.user_pool_id
  }
  storage_bucket = {
    arn  = var.storage_bucket_arn
    name = var.storage_bucketName
  }
  storage_table = {
    stream_arn = var.storage_table_stream_arn
    name       = var.storage_table
    arn        = var.storage_table_arn
  }
}
