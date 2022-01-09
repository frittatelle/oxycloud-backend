
variable "service" {
  type = object({
    uri         = string
    policy_arn  = string
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
variable "name" {
  type = string
}