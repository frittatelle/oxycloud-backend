output "USER_POOL_ID" {
  value = module.authorization.user_pool
}

output "USER_POOL_SUBDOMAIN" {
  value = local.user_pool_domain
}

output "CLIENT_ID" {
  value = module.authorization.client_id
}

output "IDENTITY_POOL_ID" {
  value = module.authorization.identity_pool
}

output "BUCKET_NAME" {
  value = module.storage.bucket.bucket
}

output "REGION" {
  value = var.region
}
##TODO: remove
# they still exist for the direct production of the .env file for react
output "SIGNIN_REDIRECT_URL" {
  value = local.website
}

output "SIGNOUT_REDIRECT_URL" {
  value = local.website
}
###
output "WEBSITE_URL" {
  value = local.website
}

output "HOSTING_BUCKET" {
  value = module.website.hosting_bucket
}
