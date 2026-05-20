output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint for database connections."
  value       = aws_db_proxy.main.endpoint
}

output "db_name" {
  description = "Name of the PostgreSQL database."
  value       = var.db_name
}

output "rds_secret_name" {
  description = "Name of the Secrets Manager secret containing RDS credentials."
  value       = aws_secretsmanager_secret.rds_credentials.name
}

output "dynamodb_reports_table_name" {
  description = "Name of the DynamoDB reports table."
  value       = aws_dynamodb_table.reports.name
}
