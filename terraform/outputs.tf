output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "api_url" {
  description = "Application URL (API Gateway) — serves frontend and API"
  value       = module.api.api_url
}

output "s3_bucket_name" {
  description = "S3 bucket for raw Polymarket data"
  value       = module.storage.s3_bucket_name
}

output "frontend_bucket_name" {
  description = "S3 bucket for frontend static files (upload HTML/JS/CSS here)"
  value       = module.storage.frontend_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.storage.dynamodb_table_name
}

output "fck_nat_instance_id" {
  description = "fck-nat EC2 instance ID"
  value       = module.nat.instance_id
}

output "lambda_function_name" {
  description = "API Lambda function name (update code with: aws lambda update-function-code)"
  value       = module.api.lambda_function_name
}
