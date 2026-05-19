variable "project" {
  type        = string
  description = "Project name prefix for all resource names and tags."
}

variable "suffix" {
  type        = string
  description = "Auto-generated suffix for globally-scoped resources (secrets, etc.)."
}

variable "lab_role_arn" {
  type        = string
  description = "ARN of the LabRole IAM role used by all resources."
}

variable "posts_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for storing Bluesky post data."
}

variable "dynamodb_reports_table_name" {
  type        = string
  description = "Name of the DynamoDB table for storing analysis reports."
}
