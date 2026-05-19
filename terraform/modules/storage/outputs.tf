output "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend static files."
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_arn" {
  description = "ARN of the S3 frontend bucket."
  value       = aws_s3_bucket.frontend.arn
}

output "posts_bucket_name" {
  description = "Name of the S3 bucket for Bluesky post data."
  value       = aws_s3_bucket.posts.bucket
}

output "posts_bucket_arn" {
  description = "ARN of the S3 posts bucket."
  value       = aws_s3_bucket.posts.arn
}
