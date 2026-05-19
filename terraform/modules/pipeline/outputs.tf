output "campaign_events_queue_url" {
  value = aws_sqs_queue.campaign_events.url
}

output "campaign_events_queue_arn" {
  value = aws_sqs_queue.campaign_events.arn
}

output "campaign_topics_queue_url" {
  value = aws_sqs_queue.campaign_topics.url
}

output "sns_campaign_posts_arn" {
  value = aws_sns_topic.campaign_posts.arn
}

output "schedule_group_name" {
  value = aws_scheduler_schedule_group.campaigns.name
}

output "orchestrator_function_name" {
  value = aws_lambda_function.orchestrator.function_name
}

output "scheduler_function_name" {
  value = aws_lambda_function.scheduler.function_name
}

output "fetcher_function_name" {
  value = aws_lambda_function.fetcher.function_name
}

output "s3_saver_function_name" {
  value = aws_lambda_function.s3_saver.function_name
}

output "report_generator_function_name" {
  value = aws_lambda_function.report_generator.function_name
}

output "report_writer_function_name" {
  value = aws_lambda_function.report_writer.function_name
}

output "gemini_secret_arn" {
  value = aws_secretsmanager_secret.gemini_api_key.arn
}
