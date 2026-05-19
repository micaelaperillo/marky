output "user_pool_id" {
  value       = aws_cognito_user_pool.main.id
  description = "Cognito User Pool ID."
}

output "user_pool_client_id" {
  value       = aws_cognito_user_pool_client.spa.id
  description = "Cognito App Client ID (public, no secret)."
}
