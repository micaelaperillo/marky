output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "api_url" {
  description = "Application URL (API Gateway)"
  value       = module.api.api_url
}

output "frontend_bucket_name" {
  description = "S3 bucket for frontend static files"
  value       = module.storage.frontend_bucket_name
}

output "posts_bucket_name" {
  description = "S3 bucket for Bluesky posts"
  value       = module.storage.posts_bucket_name
}

output "dynamodb_reports_table" {
  description = "DynamoDB reports table name"
  value       = module.database.dynamodb_reports_table_name
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint"
  value       = module.database.rds_proxy_endpoint
  sensitive   = true
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.auth.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.auth.user_pool_client_id
}

output "lambda_function_names" {
  description = "All Lambda function names for code deployment"
  value = {
    auth             = module.api.auth_lambda_function_name
    campaigns        = module.api.campaigns_lambda_function_name
    reports          = module.api.reports_lambda_function_name
    orchestrator     = module.pipeline.orchestrator_function_name
    fetcher          = module.pipeline.fetcher_function_name
    s3_saver         = module.pipeline.s3_saver_function_name
    report_generator = module.pipeline.report_generator_function_name
    report_writer    = module.pipeline.report_writer_function_name
  }
}

output "schedule_group_name" {
  description = "EventBridge Scheduler group for per-campaign schedules"
  value       = module.pipeline.schedule_group_name
}

output "gemini_secret_arn" {
  description = "Secrets Manager ARN for Gemini API key (set value manually)"
  value       = module.pipeline.gemini_secret_arn
  sensitive   = true
}
