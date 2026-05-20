provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = var.project
    }
  }
}

module "networking" {
  source   = "./modules/networking"
  project  = var.project
  vpc_cidr = var.vpc_cidr
  region   = var.region
}

module "security" {
  source  = "./modules/security"
  project = var.project
  vpc_id  = module.networking.vpc_id
  region  = var.region
}

module "nat" {
  source                  = "./modules/nat"
  project                 = var.project
  subnet_id               = module.networking.nat_subnet_ids[0]
  security_group_id       = module.security.nat_sg_id
  backend_route_table_ids = module.networking.backend_route_table_ids
}

module "storage" {
  source  = "./modules/storage"
  project = var.project
  suffix  = var.suffix
}

module "compute" {
  source                    = "./modules/compute"
  project                   = var.project
  vpc_id                    = module.networking.vpc_id
  backend_subnet_ids        = module.networking.backend_subnet_ids
  backend_sg_id             = module.security.backend_sg_id
  create_key_pair           = var.create_key_pair
  repo_url                  = var.repo_url
  iam_instance_profile_name = var.iam_instance_profile_name
}

module "auth" {
  source  = "./modules/auth"
  project = var.project
}

module "bluesky_ingest" {
  source               = "./modules/bluesky-ingest"
  project              = var.project
  region               = var.region
  lambda_subnet_ids    = module.networking.backend_subnet_ids
  lambda_sg_id         = module.security.lambda_sg_id
  bluesky_identifier   = var.bluesky_identifier
  bluesky_app_password = var.bluesky_app_password
}

module "bluesky_store" {
  source            = "./modules/bluesky-store"
  project           = var.project
  region            = var.region
  suffix            = var.suffix
  lambda_subnet_ids = module.networking.backend_subnet_ids
  lambda_sg_id      = module.security.lambda_sg_id
  sns_topic_arn     = module.bluesky_ingest.sns_topic_arn
}

module "api" {
  source               = "./modules/api"
  project              = var.project
  region               = var.region
  frontend_bucket_name = module.storage.frontend_bucket_name
  lambda_subnet_ids    = module.networking.backend_subnet_ids
  lambda_sg_id         = module.security.lambda_sg_id
  backend_url          = "http://${module.compute.backend_alb_dns}"
  cognito_user_pool_id = module.auth.user_pool_id
  cognito_client_id    = module.auth.user_pool_client_id
}
