# aws_cognito_user_pool.users_pool:
resource "aws_cognito_user_pool" "users_pool" {

  auto_verified_attributes = [
    "email",
  ]
  username_attributes = [
    "email",
  ]
  mfa_configuration = "OFF"
  name              = "oxygen_dev"
  tags              = {}
  username_configuration {
    case_sensitive = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
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

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "company"
    required                 = false

    string_attribute_constraints {
      max_length = "256"
      min_length = "1"
    }
  }

  schema {
    attribute_data_type      = "Number"
    developer_only_attribute = false
    mutable                  = true
    name                     = "subscription_plan"
    required                 = false
    number_attribute_constraints {
      max_value = 500
      min_value = 50
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}. "
    email_subject        = "Your verification code"
    sms_message          = "Your verification code is {####}. "
  }

  lambda_config {
    pre_sign_up       = module.verify_subscription_plan.lambda_function_arn
    post_confirmation = module.set_user_company.lambda_function_arn
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.users_pool.id
}

# aws_cognito_user_pool_client.web_client:
resource "aws_cognito_user_pool_client" "web_client" {

  refresh_token_validity = 30

  id_token_validity = 5
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  name                          = "web_client"
  prevent_user_existence_errors = "ENABLED"
  read_attributes = [
    "address",
    "birthdate",
    "custom:company",
    "custom:subscription_plan",
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

module "set_user_company" {
  source        = "./setUserCompany"
  user_pool_arn = aws_cognito_user_pool.users_pool.arn
  users_table   = var.users_table
}

module "verify_subscription_plan" {
  source        = "./verifySubscriptionPlan"
  user_pool_arn = aws_cognito_user_pool.users_pool.arn
  users_table   = var.users_table
}
