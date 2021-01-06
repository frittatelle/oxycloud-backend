# aws_iam_policy.bucket_access:
resource "aws_iam_policy" "bucket_access" {
  name = "oxygen_authenticated_user"
  path = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "mobileanalytics:PutEvents",
            "cognito-sync:*",
            "cognito-identity:*",
          ]
          Effect = "Allow"
          Resource = [
            "*"
          ]
        },
        {
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::${aws_s3_bucket.storage.bucket}/$${cognito-identity.amazonaws.com:sub}/*",
          ]
        },
        {
          Action = [
            "s3:ListBucket",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::${aws_s3_bucket.storage.bucket}",
          ]
          Condition = {
            StringLike = {
              "s3:prefix" = ["$${cognito-identity.amazonaws.com:sub}/*"]
              "s3:prefix" = ["$${cognito-identity.amazonaws.com:sub}/"]
            }
          }

        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_s3_bucket" "storage" {
  bucket_prefix = "oxygen-storage-"
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET", "HEAD", "DELETE"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}