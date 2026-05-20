variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "marky"
}


variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "marky"
}

variable "db_username" {
  type    = string
  default = "marky_admin"
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
