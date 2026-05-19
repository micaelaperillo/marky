variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "lab_role_arn" {
  type = string
}

variable "frontend_bucket_name" {
  type = string
}

variable "lambda_subnet_ids" {
  type = list(string)
}

variable "lambda_sg_id" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_client_id" {
  type = string
}

variable "rds_proxy_endpoint" {
  type = string
}

variable "db_name" {
  type = string
}

variable "rds_secret_arn" {
  type = string
}

variable "dynamodb_reports_table_name" {
  type = string
}

variable "campaign_events_queue_url" {
  type = string
}
