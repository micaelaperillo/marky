variable "project" {
  type = string
}

variable "suffix" {
  type = string
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

variable "subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  type = string
}

variable "lab_role_arn" {
  type = string
}
