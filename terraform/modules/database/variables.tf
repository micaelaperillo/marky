variable "project" {
  type        = string
  description = "Project name prefix for all resource names and tags."
}

variable "suffix" {
  type        = string
  description = "Auto-generated suffix for globally-scoped resources (secrets, etc.)."
}

variable "db_instance_class" {
  type        = string
  default     = "db.t4g.micro"
  description = "RDS instance class."
}

variable "db_name" {
  type        = string
  default     = "marky"
  description = "Name of the PostgreSQL database to create."
}

variable "db_username" {
  type        = string
  default     = "marky_admin"
  description = "Master username for the RDS instance."
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the DB subnet group and RDS Proxy."
}

variable "rds_sg_id" {
  type        = string
  description = "Security group ID for the RDS instance and RDS Proxy."
}

variable "lab_role_arn" {
  type        = string
  description = "ARN of the LabRole IAM role used by all resources."
}
