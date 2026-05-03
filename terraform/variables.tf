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
  description = "Unique suffix for globally-scoped resources (S3 buckets). Max 13 chars."

  validation {
    condition     = length(var.suffix) <= 13
    error_message = "Suffix must be 13 characters or fewer."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "create_key_pair" {
  type        = bool
  default     = true
  description = "Generate EC2 key pair for backend and save .pem locally."
}

variable "repo_url" {
  type    = string
  default = "https://github.com/micaelaperillo/marky.git"
}

variable "iam_instance_profile_name" {
  type        = string
  default     = "LabInstanceProfile"
  description = "Pre-existing IAM instance profile for EC2 instances (AWS Academy: LabInstanceProfile)."
}

variable "cookie_secret" {
  type        = string
  sensitive   = true
  description = "Secret used to sign session cookies in the Express API."
}
