variable "project" {
  type        = string
  description = "Project name prefix for all resource names and tags."
}

variable "suffix" {
  type        = string
  description = "Auto-generated suffix for globally-scoped S3 bucket names."
}
