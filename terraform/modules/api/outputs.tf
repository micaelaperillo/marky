output "api_url" {
  value = aws_api_gateway_stage.prod.invoke_url
}

output "auth_lambda_function_name" {
  value = aws_lambda_function.auth.function_name
}

output "campaigns_lambda_function_name" {
  value = aws_lambda_function.campaigns.function_name
}

output "reports_lambda_function_name" {
  value = aws_lambda_function.reports.function_name
}
