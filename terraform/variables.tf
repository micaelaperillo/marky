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
