variable "project" {
  type = string
}

variable "backend_subnet_ids" {
  type = list(string)
}

variable "backend_sg_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "create_key_pair" {
  type    = bool
  default = true
}

variable "repo_url" {
  type    = string
  default = "https://github.com/micaelaperillo/marky.git"
}

variable "iam_instance_profile_name" {
  type        = string
  description = "Pre-existing IAM instance profile name for EC2 instances."
}
