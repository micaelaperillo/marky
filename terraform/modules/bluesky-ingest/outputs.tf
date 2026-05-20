output "sqs_queue_url" {
  value       = aws_sqs_queue.campaigns.url
  description = "Pass this to the Go lambda as SQS_QUEUE_URL"
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.campaigns.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.bluesky_results.arn
}
