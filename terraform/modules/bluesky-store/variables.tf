variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "suffix" {
  type        = string
  description = "Unique suffix for globally-scoped resources (S3 buckets)."
}

variable "lambda_subnet_ids" {
  type = list(string)
}

variable "lambda_sg_id" {
  type = string
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS topic that publishes BlueSky results."
}
