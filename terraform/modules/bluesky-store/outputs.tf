output "s3_bucket_name" {
  value       = aws_s3_bucket.bluesky_raw.bucket
  description = "Name of the S3 bucket storing raw BlueSky results"
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.bluesky_raw.url
  description = "URL of the SQS queue receiving SNS notifications"
}