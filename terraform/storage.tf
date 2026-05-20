module "storage" {
  source  = "./modules/storage"
  project = var.project
  suffix  = random_string.suffix.result
}
