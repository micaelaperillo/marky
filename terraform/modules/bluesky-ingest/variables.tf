variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "lambda_subnet_ids" {
  type = list(string)
}

variable "lambda_sg_id" {
  type = string
}

variable "bluesky_identifier" {
  type        = string
  description = "BlueSky handle (e.g. user.bsky.social)"
}

variable "bluesky_app_password" {
  type        = string
  sensitive   = true
  description = "BlueSky app password (from bsky.app/settings/app-passwords)"
}