variable "project" {
  type = string
}

variable "region" {
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

variable "backend_url" {
  type        = string
  description = "Internal ALB URL for the Python analysis backend."
}

variable "cookie_secret" {
  type      = string
  sensitive = true
}
