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
  lambda_dist_base  = local.lambda_dist_base
  lambda_subnet_ids = module.networking.backend_subnet_ids
  lambda_sg_id      = module.networking.lambda_sg_id

  # The apply-time migrator reaches Secrets Manager / CloudWatch Logs through the
  # interface endpoints in the networking module; make that ordering explicit
  # (consuming only subnet/SG IDs would not depend on the endpoint resources).
  depends_on = [module.networking]
}
