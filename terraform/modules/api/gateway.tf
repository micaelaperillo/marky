# ============================================================
# API Gateway REST API
# ============================================================

resource "aws_api_gateway_rest_api" "main" {
  name                     = "${var.project}-api"
  binary_media_types       = ["image/*", "font/*", "application/wasm", "application/octet-stream"]
  minimum_compression_size = 1024

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = { Name = "${var.project}-api" }
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = var.lab_role_arn
}

# ============================================================
# Cognito Authorizer
# ============================================================

resource "aws_api_gateway_authorizer" "cognito" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  name          = "${var.project}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  provider_arns = ["arn:aws:cognito-idp:${var.region}:${var.account_id}:userpool/${var.cognito_user_pool_id}"]
}

# ============================================================
# Deployment + Stage
# ============================================================

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      # Root -> S3 index.html
      aws_api_gateway_method.root_get,
      aws_api_gateway_integration.root_get_s3,
      aws_api_gateway_method_response.root_get_200,
      aws_api_gateway_method_response.root_get_404,
      aws_api_gateway_integration_response.root_get_200,
      aws_api_gateway_integration_response.root_get_4xx,
      # Static assets -> S3
      aws_api_gateway_method.static_get,
      aws_api_gateway_integration.static_get_s3,
      aws_api_gateway_method_response.static_get_200,
      aws_api_gateway_method_response.static_get_404,
      aws_api_gateway_integration_response.static_get_200,
      aws_api_gateway_integration_response.static_get_4xx,
      # _app build assets -> S3
      aws_api_gateway_method.app_assets_get,
      aws_api_gateway_integration.app_assets_s3,
      aws_api_gateway_method_response.app_assets_200,
      aws_api_gateway_method_response.app_assets_404,
      aws_api_gateway_integration_response.app_assets_200,
      aws_api_gateway_integration_response.app_assets_4xx,
      # Auth -> Lambda
      aws_api_gateway_method.auth_any,
      aws_api_gateway_integration.auth_lambda,
      aws_api_gateway_method.auth_proxy_any,
      aws_api_gateway_integration.auth_proxy_lambda,
      # Campaigns -> Lambda
      aws_api_gateway_method.campaigns_any,
      aws_api_gateway_integration.campaigns_lambda,
      aws_api_gateway_method.campaigns_proxy_any,
      aws_api_gateway_integration.campaigns_proxy_lambda,
      # Reports -> Lambda
      aws_api_gateway_method.reports_any,
      aws_api_gateway_integration.reports_lambda,
      aws_api_gateway_method.reports_proxy_any,
      aws_api_gateway_integration.reports_proxy_lambda,
      # SPA fallback -> S3 index.html
      aws_api_gateway_method.spa_fallback_get,
      aws_api_gateway_integration.spa_fallback_s3,
      aws_api_gateway_method_response.spa_fallback_200,
      aws_api_gateway_method_response.spa_fallback_404,
      aws_api_gateway_integration_response.spa_fallback_200,
      aws_api_gateway_integration_response.spa_fallback_4xx,
      # Gateway-level error responses
      aws_api_gateway_gateway_response.default_4xx,
      aws_api_gateway_gateway_response.default_5xx,
      # Cognito authorizer (force redeploy if its config changes, e.g. user pool recreated)
      aws_api_gateway_authorizer.cognito,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration_response.root_get_200,
    aws_api_gateway_integration_response.root_get_4xx,
    aws_api_gateway_integration_response.static_get_200,
    aws_api_gateway_integration_response.static_get_4xx,
    aws_api_gateway_integration_response.app_assets_200,
    aws_api_gateway_integration_response.app_assets_4xx,
    aws_api_gateway_integration.auth_lambda,
    aws_api_gateway_integration.auth_proxy_lambda,
    aws_api_gateway_integration.campaigns_lambda,
    aws_api_gateway_integration.campaigns_proxy_lambda,
    aws_api_gateway_integration.reports_lambda,
    aws_api_gateway_integration.reports_proxy_lambda,
    aws_api_gateway_integration_response.spa_fallback_200,
    aws_api_gateway_integration_response.spa_fallback_4xx,
  ]
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project}-api"
  retention_in_days = 14
  tags              = { Name = "${var.project}-api-gw-logs" }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id          = aws_api_gateway_rest_api.main.id
  deployment_id        = aws_api_gateway_deployment.main.id
  stage_name           = "prod"
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      httpMethod         = "$context.httpMethod"
      resourcePath       = "$context.resourcePath"
      status             = "$context.status"
      responseLength     = "$context.responseLength"
      requestTime        = "$context.requestTime"
      integrationLatency = "$context.integrationLatency"
      errorMessage       = "$context.error.message"
      userAgent          = "$context.identity.userAgent"
      protocol           = "$context.protocol"
    })
  }

  tags = { Name = "${var.project}-api-stage" }

  # API Gateway logging requires the account-level CloudWatch role first.
  depends_on = [aws_api_gateway_account.main]
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
    logging_level          = "ERROR"
    data_trace_enabled     = false
    metrics_enabled        = true
  }

  depends_on = [aws_api_gateway_account.main]
}

resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{\"error\": \"Client error\"}"
  }
}

resource "aws_api_gateway_gateway_response" "default_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  response_type = "DEFAULT_5XX"

  response_templates = {
    "application/json" = "{\"error\": \"Internal server error\"}"
  }
}
