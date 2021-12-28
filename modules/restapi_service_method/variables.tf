
variable "service" {
  type = object({
    uri         = string
    invoke_role = string
    http_method = string
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
    parameters             = any
    integration_parameters = any
    timeout_ms             = number
    templates              = map(string)
  })
}

variable "http_method" {
  type = string
}