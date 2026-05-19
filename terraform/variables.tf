variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "marky"
}

variable "suffix" {
  type        = string
  description = "Unique suffix for globally-scoped resources (S3 buckets, secrets). Max 13 chars."

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.suffix)) && length(var.suffix) >= 1 && length(var.suffix) <= 13
    error_message = "Suffix must be 1-13 lowercase alphanumeric characters or hyphens (cannot start/end with hyphen)."
  }
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
