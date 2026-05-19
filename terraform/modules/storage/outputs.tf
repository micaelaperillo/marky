output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}

output "posts_bucket_name" {
  value = aws_s3_bucket.posts.bucket
}

output "posts_bucket_arn" {
  value = aws_s3_bucket.posts.arn
}
