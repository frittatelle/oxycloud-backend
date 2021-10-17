resource "aws_lambda_permission" "allow_bucket_on_created" {
  count         = var.on_created_lambda == null ? 0 : 1
  statement_id  = "AllowExecutionFromS3BucketOnCreated"
  action        = "lambda:InvokeFunction"
  function_name = var.on_created_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.storage.arn
}
resource "aws_lambda_permission" "allow_bucket_on_removed" {
  count         = var.on_removed_lambda == null ? 0 : 1
  statement_id  = "AllowExecutionFromS3BucketOnRemoved"
  action        = "lambda:InvokeFunction"
  function_name = var.on_removed_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.storage.arn
}

#BIG ISSUE
#we are allowed to do only one resource per bucket
#but i cannot put condition for lambda block
resource "aws_s3_bucket_notification" "triggers" {
  bucket = aws_s3_bucket.storage.id
  
  count         = var.on_created_lambda == null ? 0 : 1
  
  lambda_function {
    lambda_function_arn = "${var.on_created_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
  }

  #dynamic "lambda_function" {
  #  for_each = [var.on_removed_lambda]
  #  content {
  #    lambda_function_arn = lambda_function.value["arn"]
  #    events              = ["s3:ObjectRemoved:*"]
  #  }
  #}

  # There isn't an event for this btw we can use cloudwatch
  #  lambda_function {
  #    lambda_function_arn = "${on_download_lambda.arn}"
  #    events              = ["s3:ObjectCreated:*"]
  #  }
}
