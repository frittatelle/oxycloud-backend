output "hosting_bucket" {
  description = "The bucket where the file are hosted"
  value       = aws_s3_bucket.hosting.bucket
}

output "domain_name" {
  description = "The public accessible domain"
  value       = aws_cloudfront_distribution.website.domain_name
}
