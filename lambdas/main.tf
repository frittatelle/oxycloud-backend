####################################################
# Lambda Function (building locally, storing on S3,
# set allowed triggers, set policies)
####################################################
#https://github.com/terraform-aws-modules/terraform-aws-lambda/tree/master/examples/complete
module "lambda_function" {
  #source = "https://github.com/terraform-aws-modules/terraform-aws-lambda"
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.22.0"

  function_name = "document-on_created"
  description   = "Callback on creation of a new object into the storage bucket"
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  architectures = ["x86_64"]
  publish       = true

  source_path = "${path.module}/src/on_created"

  store_on_s3 = false

  #  attach_dead_letter_policy = true
  #  dead_letter_target_arn    = aws_sqs_queue.dlq.arn
}

