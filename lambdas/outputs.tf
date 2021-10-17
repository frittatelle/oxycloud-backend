output "on_created_arn" {
  description = "The ARN of the Lambda Function OnCreate"
  value       = module.lambda_function.lambda_function_arn
}
