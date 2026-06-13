variable "region" {
  description = "AWS region for all resource deployment."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name prefix for all resource names and tags."
  type        = string
  default     = "marky"
}


variable "vpc_cidr" {
  description = "CIDR block for the project VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "db_instance_class" {
  description = "RDS instance class for the PostgreSQL database."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Name of the initial PostgreSQL database."
  type        = string
  default     = "marky"
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance."
  type        = string
  default     = "marky_admin"
}

variable "gemini_api_key" {
  type        = string
  description = "Google Gemini API key for report generation."
  sensitive   = true
}

variable "bluesky_identifier" {
  type        = string
  description = "BlueSky handle (e.g. user.bsky.social)"
  default     = null
  sensitive   = true
}

variable "bluesky_app_password" {
  type        = string
  description = "BlueSky app password (from bsky.app/settings/app-passwords)"
  default     = null
  sensitive   = true
}
