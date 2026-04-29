output "s3_bucket_name" {
  value = aws_s3_bucket.raw_data.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.raw_data.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.data.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.data.arn
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_arn" {
  value = aws_s3_bucket.frontend.arn
}
