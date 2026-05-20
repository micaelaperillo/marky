module "api" {
  source = "./modules/api"

  project                     = var.project
  region                      = var.region
  account_id                  = data.aws_caller_identity.current.account_id
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
