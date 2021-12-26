variable "rest_api_id" {}
variable "resource_id" {}

variable "region" {}

variable "storage_bucket_id" {}

variable "storage_bucket_arn" {}
variable "storage_table" {}
variable "authorizer_id" {}
variable "rest_api_execution_arn" {}
variable "parent_resource_path" {}

variable "lambda" {
  value = {
    arn = null
    name = null
    description = null
    policy = { arn=null }
  }
}

variable "storage_bucket" {
}

variable "storage_table" {
  value = {
    arn = null
    name = null
    stream_arn = null
  }
}
