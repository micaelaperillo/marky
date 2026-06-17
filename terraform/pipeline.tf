module "pipeline" {
  source = "./modules/pipeline"

  project                     = var.project
  suffix                      = random_string.suffix.result
  lab_role_arn                = local.lab_role_arn
  posts_bucket_name           = module.storage.posts_bucket_name
  dynamodb_reports_table_name = module.database.dynamodb_reports_table_name
  lambda_dist_base            = local.lambda_dist_base
  gemini_api_key              = var.gemini_api_key
  gemini_ai_model             = var.gemini_ai_model
  bluesky_identifier          = var.bluesky_identifier
  bluesky_app_password        = var.bluesky_app_password
}
