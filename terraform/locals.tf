resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false

  lifecycle {
    ignore_changes = all
  }
}

locals {
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}
