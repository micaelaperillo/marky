provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.project
    }
  }
}

data "aws_caller_identity" "current" {}

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
  suffix            = var.suffix
  db_instance_class = var.db_instance_class
  db_name       = var.db_name
  db_username   = var.db_username
  subnet_ids    = module.networking.backend_subnet_ids
  rds_sg_id     = module.networking.rds_sg_id
  lab_role_arn  = local.lab_role_arn
}

module "storage" {
  source  = "./modules/storage"
  project = var.project
  suffix  = var.suffix
}

module "pipeline" {
  source = "./modules/pipeline"

  project                     = var.project
  suffix                      = var.suffix
  lab_role_arn                = local.lab_role_arn
  posts_bucket_name           = module.storage.posts_bucket_name
  dynamodb_reports_table_name = module.database.dynamodb_reports_table_name
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
  rds_proxy_endpoint          = module.database.rds_proxy_endpoint
  db_name                     = module.database.db_name
  rds_secret_arn              = module.database.rds_secret_arn
  dynamodb_reports_table_name = module.database.dynamodb_reports_table_name
  campaign_events_queue_url   = module.pipeline.campaign_events_queue_url
}
