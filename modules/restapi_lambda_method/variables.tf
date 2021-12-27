
variable "lambda" {
  type = object({
    name                  = string
    description           = string
    policy_arn            = string
    timeout               = number
    source_path           = string
    environment_variables = map(string)
  })
}

variable "apigateway" {
  type = object({
    arn = string
    id  = string
  })
}

variable "authorizer" {
  type = object({
    type = string
    id   = string
  })
}

variable "resource" {
  type = object({
    id   = string
    path = string
  })
}

variable "responses" {
  type = map(object({
    integration_parameters        = any
    integration_templates         = any
    integration_selection_pattern = any
    integration_status_code       = any
    integration_content_handling  = string

    models      = any
    parameters  = any
    status_code = number
  }))
}

variable "request" {
  type = object({
    parameters = any
    timeout_ms = number
  })
}

variable "http_method" {
  type = string
}