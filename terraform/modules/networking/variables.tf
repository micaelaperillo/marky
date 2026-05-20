variable "project" {
  type        = string
  description = "Project name prefix for all resource names and tags."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "region" {
  type        = string
  description = "AWS region for resource deployment."
}
