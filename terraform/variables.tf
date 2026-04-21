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
  description = "Unique suffix for globally-scoped resources (S3 bucket, ALB target group). Max 13 chars."

  validation {
    condition     = length(var.suffix) <= 13
    error_message = "Suffix must be 13 characters or fewer (AWS target group name 32-char limit)."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "create_key_pairs" {
  type        = bool
  default     = true
  description = "Generate new EC2 key pairs and save .pem files locally. Set false if keys already exist in AWS."
}

variable "repo_url" {
  type    = string
  default = "https://github.com/micaelaperillo/marky.git"
}

variable "iam_instance_profile_name" {
  type        = string
  default     = "LabInstanceProfile"
  description = "Pre-existing IAM instance profile to attach to EC2 instances (AWS Academy: LabInstanceProfile)."
}
