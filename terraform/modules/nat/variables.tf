variable "project" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "NAT subnet ID (must be public, with IGW route)."
}

variable "security_group_id" {
  type = string
}

variable "backend_route_table_ids" {
  type        = list(string)
  description = "Backend route table IDs — each gets a 0.0.0.0/0 route to fck-nat."
}
