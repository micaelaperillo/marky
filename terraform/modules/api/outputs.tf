output "api_url" {
  description = "Invoke URL of the API Gateway production stage."
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "auth_lambda_function_name" {
  description = "Name of the auth Lambda function."
  value       = aws_lambda_function.auth.function_name
}

output "campaigns_lambda_function_name" {
  description = "Name of the campaigns Lambda function."
  value       = aws_lambda_function.campaigns.function_name
}

output "reports_lambda_function_name" {
  description = "Name of the reports Lambda function."
  value       = aws_lambda_function.reports.function_name
}
