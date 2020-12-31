variable "signin_redirect_url" { default = "http://localhost:3000/" }
variable "signout_redirect_url" { default = "http://localhost:3000/" }
variable "region" { default = "us-east-1" }
variable "user_pool_domain" { default = "user-pool-domain-xxxxx" }

provider "aws" {
  access_key = ""
  secret_key = ""
  region     = var.region
}

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

# aws_cognito_user_pool.users_pool:
resource "aws_cognito_user_pool" "users_pool" {
  alias_attributes = [
    "preferred_username",
  ]
  auto_verified_attributes = [
    "email",
  ]
  mfa_configuration = "OFF"
  name              = "oxygen_dev"
  tags              = {}

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false

    invite_message_template {
      email_message = "Your username is {username} and temporary password is {####}. "
      email_subject = "Your temporary password"
      sms_message   = "Your username is {username} and temporary password is {####}. "
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }

  username_configuration {
    case_sensitive = false
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}. "
    email_subject        = "Your verification code"
    sms_message          = "Your verification code is {####}. "
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.users_pool.id
}

# aws_cognito_user_pool_client.web_client:
resource "aws_cognito_user_pool_client" "web_client" {
  allowed_oauth_flows = [
    "code",
    "implicit",
  ]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "email",
    "openid",
    "phone",
  ]
  callback_urls = [
    var.signin_redirect_url
  ]
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
  logout_urls = [
    var.signout_redirect_url, #the url of the deployed app
  ]
  name                          = "web_client"
  prevent_user_existence_errors = "ENABLED"
  read_attributes = [
    "address",
    "birthdate",
    "email",
    "email_verified",
    "family_name",
    "gender",
    "given_name",
    "locale",
    "middle_name",
    "name",
    "nickname",
    "phone_number",
    "phone_number_verified",
    "picture",
    "preferred_username",
    "profile",
    "updated_at",
    "website",
    "zoneinfo",
  ]
  refresh_token_validity = 30
  supported_identity_providers = [
    "COGNITO",
  ]
  user_pool_id = aws_cognito_user_pool.users_pool.id
  write_attributes = [
    "address",
    "birthdate",
    "email",
    "family_name",
    "gender",
    "given_name",
    "locale",
    "middle_name",
    "name",
    "nickname",
    "phone_number",
    "picture",
    "preferred_username",
    "profile",
    "updated_at",
    "website",
    "zoneinfo",
  ]
}

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
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.authenticated.name
  policy_arn = aws_iam_policy.bucket_access.arn
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

resource "aws_s3_bucket" "storage" {
  bucket_prefix = "oxygen-storage-"
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET", "HEAD", "DELETE"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

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
  value = var.signin_redirect_url
}

output "SIGNOUT_REDIRECT_URL" {
  value = var.signout_redirect_url
}
