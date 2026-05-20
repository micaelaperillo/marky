module "networking" {
  source   = "./modules/networking"
  project  = var.project
  vpc_cidr = var.vpc_cidr
  region   = var.region
}
