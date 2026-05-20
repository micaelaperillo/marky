output "campaign_events_queue_url" {
  description = "URL of the campaign events FIFO SQS queue."
  value       = aws_sqs_queue.campaign_events.url
}

output "campaign_events_queue_arn" {
  description = "ARN of the campaign events FIFO SQS queue."
  value       = aws_sqs_queue.campaign_events.arn
}

output "campaign_topics_queue_url" {
  description = "URL of the campaign topics FIFO SQS queue."
  value       = aws_sqs_queue.campaign_topics.url
}

output "sns_campaign_posts_arn" {
  description = "ARN of the campaign posts SNS FIFO topic."
  value       = aws_sns_topic.campaign_posts.arn
}

output "schedule_group_name" {
  description = "Name of the EventBridge Scheduler group for per-campaign schedules."
  value       = aws_scheduler_schedule_group.campaigns.name
}

output "orchestrator_function_name" {
  description = "Name of the orchestrator Lambda function."
  value       = aws_lambda_function.orchestrator.function_name
}

output "fetcher_function_name" {
  description = "Name of the fetcher Lambda function."
  value       = aws_lambda_function.fetcher.function_name
}

output "s3_saver_function_name" {
  description = "Name of the S3 saver Lambda function."
  value       = aws_lambda_function.s3_saver.function_name
}

output "report_generator_function_name" {
  description = "Name of the report generator Lambda function."
  value       = aws_lambda_function.report_generator.function_name
}

output "report_writer_function_name" {
  description = "Name of the report writer Lambda function."
  value       = aws_lambda_function.report_writer.function_name
}

output "reports_queue_url" {
  description = "URL of the reports FIFO SQS queue."
  value       = aws_sqs_queue.reports.url
}

output "gemini_secret_arn" {
  description = "ARN of the Secrets Manager secret for the Gemini API key."
  value       = aws_secretsmanager_secret.gemini_api_key.arn
}
