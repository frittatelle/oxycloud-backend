module "files_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name             = "users_storage_files"
  hash_key         = "user_id"
  range_key        = "file_id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  attributes = [
    {
      name = "file_id"
      type = "S"
    },
    {
      name = "user_id"
      type = "S"
    },
  ]
}

locals {
  table_arn        = module.files_table.dynamodb_table_arn
  table_name       = module.files_table.dynamodb_table_id
  table_stream_arn = module.files_table.dynamodb_table_stream_arn
}


module "users_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name             = "users"
  hash_key         = "user_id"
  range_key        = "company"
  attributes = [
    {
      name = "company"
      type = "S"
    },
    {
      name = "user_id"
      type = "S"
    },
  ]
}


output "files_table" {
  value = tomap({
    arn        = "${module.files_table.dynamodb_table_arn}",
    name       = "${module.files_table.dynamodb_table_id}",
    stream_arn = "${module.files_table.dynamodb_table_stream_arn}",
  })
}

output "users_table" {
  value = tomap({
    arn        = "${module.users_table.dynamodb_table_arn}",
    name       = "${module.users_table.dynamodb_table_id}",
    stream_arn = "${module.users_table.dynamodb_table_stream_arn}",
  })
}
