variable "project" {
  type        = string
  description = "Project name prefix for all resource names and tags."
}

variable "lambda_dist_base" {
  type        = string
  description = "Base path to the Lambda workspace apps directory. Null = use stubs."
  default     = null
  nullable    = true
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

variable "orchestrator_max_concurrency" {
  type        = number
  description = "Maximum concurrent Lambda invocations for the orchestrator ESM."
  default     = 5

  validation {
    condition     = var.orchestrator_max_concurrency >= 2 && var.orchestrator_max_concurrency <= 1000
    error_message = "Maximum concurrency must be between 2 and 1000."
  }
}

variable "fetcher_max_concurrency" {
  type        = number
  description = "Maximum concurrent Lambda invocations for the fetcher ESM."
  default     = 5

  validation {
    condition     = var.fetcher_max_concurrency >= 2 && var.fetcher_max_concurrency <= 1000
    error_message = "Maximum concurrency must be between 2 and 1000."
  }
}

variable "s3_saver_max_concurrency" {
  type        = number
  description = "Maximum concurrent Lambda invocations for the S3 saver ESM."
  default     = 10

  validation {
    condition     = var.s3_saver_max_concurrency >= 2 && var.s3_saver_max_concurrency <= 1000
    error_message = "Maximum concurrency must be between 2 and 1000."
  }
}

variable "report_generator_max_concurrency" {
  type        = number
  description = "Maximum concurrent Lambda invocations for the report generator ESM."
  default     = 2

  validation {
    condition     = var.report_generator_max_concurrency >= 2 && var.report_generator_max_concurrency <= 1000
    error_message = "Maximum concurrency must be between 2 and 1000."
  }
}

variable "report_writer_max_concurrency" {
  type        = number
  description = "Maximum concurrent Lambda invocations for the report writer ESM."
  default     = 5

  validation {
    condition     = var.report_writer_max_concurrency >= 2 && var.report_writer_max_concurrency <= 1000
    error_message = "Maximum concurrency must be between 2 and 1000."
  }
}

variable "gemini_api_key" {
  type        = string
  description = "Google Gemini API key for report generation."
  sensitive   = true
}

variable "bluesky_identifier" {
  type        = string
  description = "Bluesky account identifier for the fetcher Lambda."
  default     = null
  sensitive   = true
}

variable "bluesky_app_password" {
  type        = string
  description = "Bluesky app password for the fetcher Lambda."
  default     = null
  sensitive   = true
}
