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
  subnet_id               = module.networking.nat_subnet_ids[0] # Single fck-nat in AZ1
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
  suffix                    = var.suffix
  vpc_id                    = module.networking.vpc_id
  frontend_subnet_ids       = module.networking.frontend_subnet_ids
  backend_subnet_ids        = module.networking.backend_subnet_ids
  frontend_sg_id            = module.security.frontend_sg_id
  backend_sg_id             = module.security.backend_sg_id
  alb_sg_id                 = module.security.alb_sg_id
  create_key_pairs          = var.create_key_pairs
  repo_url                  = var.repo_url
  iam_instance_profile_name = var.iam_instance_profile_name
}
