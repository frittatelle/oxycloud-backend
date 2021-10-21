resource "aws_lambda_permission" "allow_bucket_on_created" {
  count = var.on_created_lambda_arn == null ? 0 : 1
  statement_id  = "AllowExecutionFromS3BucketOnCreated"
  action        = "lambda:InvokeFunction"
  function_name = var.on_created_lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.storage.arn
}

#BIG ISSUE
#we are allowed to do only one resource per bucket
#but i cannot put condition for lambda block
#at this time we just trigger creation
resource "aws_s3_bucket_notification" "triggers" {
  bucket = aws_s3_bucket.storage.id

  count = var.on_created_lambda_arn == null ? 0 : 1

  lambda_function {
    lambda_function_arn = var.on_created_lambda_arn
    events              = ["s3:ObjectCreated:*"]
  }

}
