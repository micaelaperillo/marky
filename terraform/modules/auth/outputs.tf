output "user_pool_id" {
  description = "Cognito User Pool ID."
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  description = "Cognito App Client ID (public, no secret)."
  value       = aws_cognito_user_pool_client.spa.id
}
