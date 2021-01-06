# aws_cognito_identity_pool.identities_pool:
resource "aws_cognito_identity_pool" "identities_pool" {
  allow_unauthenticated_identities = false
  identity_pool_name               = "oxygen_idp"

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.web_client.id
    provider_name           = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.users_pool.id}"
    server_side_token_check = false
  }
}

# aws_cognito_identity_pool_roles_attachment.identities_pool_roles:
resource "aws_cognito_identity_pool_roles_attachment" "identities_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.identities_pool.id
  roles = {
    "authenticated"   = aws_iam_role.authenticated.arn
    "unauthenticated" = aws_iam_role.unauthenticated.arn
  }
}

# aws_iam_role.authenticated:
resource "aws_iam_role" "authenticated" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            "ForAnyValue:StringLike" = {
              "cognito-identity.amazonaws.com:amr" = "authenticated"
            }
            StringEquals = {
              "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identities_pool.id
            }
          }
          Effect = "Allow"
          Principal = {
            Federated = "cognito-identity.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = true
  max_session_duration  = 3600
  name                  = "Oxy_idp_Auth_role"
  tags                  = {}
}

# aws_iam_role.unauthenticated:
resource "aws_iam_role" "unauthenticated" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            "ForAnyValue:StringLike" = {
              "cognito-identity.amazonaws.com:amr" = "unauthenticated"
            }
            StringEquals = {
              "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identities_pool.id
            }
          }
          Effect = "Allow"
          Principal = {
            Federated = "cognito-identity.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = true
  max_session_duration  = 3600
  name                  = "Oxy_idp_Unauth_role"
  tags                  = {}
}
