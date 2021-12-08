module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name      = "users_storage_files"
  hash_key  = "user_id"
  range_key = "file_id"
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

output "table" {
  value = tomap({
    arn  = "${module.dynamodb_table.dynamodb_table_arn}",
    name = "${module.dynamodb_table.dynamodb_table_id}",
  })
}
