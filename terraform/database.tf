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
