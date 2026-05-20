check "bluesky_credentials_paired" {
  assert {
    condition     = (var.bluesky_identifier == null) == (var.bluesky_app_password == null)
    error_message = "bluesky_identifier and bluesky_app_password must both be set or both be null."
  }
}

provider "aws" {
  region      = var.region
  max_retries = 30

  default_tags {
    tags = {
      Project = var.project
    }
  }
}

data "aws_caller_identity" "current" {}

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

module "networking" {
  source   = "./modules/networking"
  project  = var.project
  vpc_cidr = var.vpc_cidr
  region   = var.region
}

module "auth" {
  source  = "./modules/auth"
  project = var.project
}

module "database" {
  source = "./modules/database"

  project           = var.project
  suffix            = random_string.suffix.result
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  subnet_ids        = module.networking.backend_subnet_ids
  rds_sg_id         = module.networking.rds_sg_id
  lab_role_arn      = local.lab_role_arn
  lambda_dist_base  = "${path.root}/../lambdas/apps"
  lambda_subnet_ids = module.networking.backend_subnet_ids
  lambda_sg_id      = module.networking.lambda_sg_id
}

module "storage" {
  source  = "./modules/storage"
  project = var.project
  suffix  = random_string.suffix.result
}

module "pipeline" {
  source = "./modules/pipeline"

  project                     = var.project
  suffix                      = random_string.suffix.result
  lab_role_arn                = local.lab_role_arn
  posts_bucket_name           = module.storage.posts_bucket_name
  dynamodb_reports_table_name = module.database.dynamodb_reports_table_name
  lambda_dist_base            = "${path.root}/../lambdas/apps"
  bluesky_identifier          = var.bluesky_identifier
  bluesky_app_password        = var.bluesky_app_password
}

module "api" {
  source = "./modules/api"

  project                     = var.project
  region                      = var.region
  lab_role_arn                = local.lab_role_arn
  frontend_bucket_name        = module.storage.frontend_bucket_name
  lambda_subnet_ids           = module.networking.backend_subnet_ids
  lambda_sg_id                = module.networking.lambda_sg_id
  cognito_user_pool_id        = module.auth.user_pool_id
  cognito_client_id           = module.auth.user_pool_client_id
  rds_secret_name             = module.database.rds_secret_name
  dynamodb_reports_table_name = module.database.dynamodb_reports_table_name
  campaign_events_queue_url   = module.pipeline.campaign_events_queue_url
  lambda_dist_base            = "${path.root}/../lambdas/apps"
}
