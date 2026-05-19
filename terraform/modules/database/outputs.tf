output "rds_proxy_endpoint" {
  value = aws_db_proxy.main.endpoint
}

output "db_name" {
  value = var.db_name
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}

output "dynamodb_reports_table_name" {
  value = aws_dynamodb_table.reports.name
}
