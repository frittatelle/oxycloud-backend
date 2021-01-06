
resource "aws_s3_bucket" "hosting" {
  bucket_prefix = "oxy-website-"
  force_destroy = true #this is not working we need to empty the bucket

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

}

resource "aws_s3_bucket_policy" "hosting" {
  bucket = aws_s3_bucket.hosting.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForWebsiteEndpointsPublicContent",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": {
        "AWS":"${aws_cloudfront_origin_access_identity.website.iam_arn}"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.hosting.arn}/*",
        "${aws_s3_bucket.hosting.arn}"
      ]
    }
  ]
}
POLICY
}
