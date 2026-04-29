output "api_url" {
  description = "Base URL (API Gateway stage invoke URL)"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "lambda_function_name" {
  value = aws_lambda_function.api.function_name
}
