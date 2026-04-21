output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "Frontend ALB DNS name — use this to access the app"
  value       = module.compute.alb_dns_name
}

output "s3_bucket_name" {
  description = "S3 bucket for raw Polymarket data"
  value       = module.storage.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.storage.dynamodb_table_name
}

output "fck_nat_instance_id" {
  description = "fck-nat EC2 instance ID"
  value       = module.nat.instance_id
}
