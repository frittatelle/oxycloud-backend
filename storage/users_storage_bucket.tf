resource "aws_s3_bucket" "storage" {
  bucket_prefix = "oxygen-storage-"
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET", "HEAD", "DELETE"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}
