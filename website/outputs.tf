output "hosting_bucket" {
  description = "The bucket where the file are hosted"
  value       = aws_s3_bucket.hosting.bucket
}

output "domain_name" {
  description = "The public accessible domain"
  value       = var.use_cdn? aws_cloudfront_distribution.website[0].domain_name : aws_s3_bucket.hosting.bucket_domain_name
}
