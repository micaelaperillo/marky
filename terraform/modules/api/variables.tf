variable "project" {
  type        = string
  description = "Project name prefix for all resource names and tags."
}

variable "account_id" {
  type        = string
  description = "AWS account ID for constructing ARNs."
}

variable "lambda_dist_base" {
  type        = string
  description = "Base path to the Lambda workspace apps directory. Null = use stubs."
  default     = null
  nullable    = true
}

variable "region" {
  type        = string
  description = "AWS region for resource deployment."
}

variable "lab_role_arn" {
  type        = string
  description = "ARN of the LabRole IAM role used by all resources."
}

variable "frontend_bucket_name" {
  type        = string
  description = "Name of the S3 bucket serving frontend static files."
}

variable "lambda_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for VPC-attached Lambda functions."
}

variable "lambda_sg_id" {
  type        = string
  description = "Security group ID for VPC-attached Lambda functions."
}

variable "cognito_user_pool_id" {
  type        = string
  description = "Cognito User Pool ID for JWT validation."
}

variable "cognito_client_id" {
  type        = string
  description = "Cognito App Client ID for JWT validation."
}

variable "rds_secret_name" {
  type        = string
  description = "Name of the Secrets Manager secret with RDS credentials."
}

variable "dynamodb_reports_table_name" {
  type        = string
  description = "Name of the DynamoDB table for analysis reports."
}

variable "campaign_events_queue_url" {
  type        = string
  description = "URL of the campaign events FIFO SQS queue."
}
