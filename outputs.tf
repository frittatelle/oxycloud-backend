output "USER_POOL_ID" {
  value = aws_cognito_user_pool.users_pool.id
}

output "USER_POOL_SUBDOMAIN" {
  value = aws_cognito_user_pool_domain.main.domain
}

output "CLIENT_ID" {
  value = aws_cognito_user_pool_client.web_client.id
}

output "IDENTITY_POOL_ID" {
  value = aws_cognito_identity_pool.identities_pool.id
}

output "BUCKET_NAME" {
  value = aws_s3_bucket.storage.bucket
}

output "REGION" {
  value = var.region
}

output "SIGNIN_REDIRECT_URL" {
  value = local.callback_url
}

output "SIGNOUT_REDIRECT_URL" {
  value = local.callback_url
}

output "WEBSITE_URL" {
  value = local.callback_url
}

output "HOSTING_BUCKET" {
  value = aws_s3_bucket.hosting.id
}
