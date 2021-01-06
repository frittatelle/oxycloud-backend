output "user_pool" {
  value = aws_cognito_user_pool.users_pool.id
}

output "client_id" {
  value = aws_cognito_user_pool_client.web_client.id
}

output "identity_pool" {
  value = aws_cognito_identity_pool.identities_pool.id
}

output "authenticated_role_name" {
  value = aws_iam_role.authenticated.name
}
