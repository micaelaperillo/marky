locals {
  s3_uri_base  = "arn:aws:apigateway:${var.region}:s3:path/${var.frontend_bucket_name}"
  stub_handler = "export const handler = async (event) => ({ statusCode: 200, headers: {\"Content-Type\": \"application/json\"}, body: JSON.stringify({ message: \"stub\" }) });"
  pkg_json_esm = "{\"type\":\"module\"}"

  api_apps = {
    auth      = "users"
    campaigns = "campaigns"
    reports   = "reports"
  }
}

# ============================================================
# Lambda Functions
# ============================================================

data "archive_file" "auth" {
  type        = "zip"
  output_path = "${path.module}/dist/auth.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/${local.api_apps["auth"]}/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }
  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

data "archive_file" "campaigns" {
  type        = "zip"
  output_path = "${path.module}/dist/campaigns.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/${local.api_apps["campaigns"]}/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }
  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

data "archive_file" "reports" {
  type        = "zip"
  output_path = "${path.module}/dist/reports.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/${local.api_apps["reports"]}/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }
  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

resource "aws_lambda_function" "auth" {
  function_name    = "${var.project}-auth"
  role             = var.lab_role_arn
  handler          = "handler.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.auth.output_path
  source_code_hash = data.archive_file.auth.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
      NODE_ENV             = "production"
    }
  }

  tags = { Name = "${var.project}-auth-lambda" }
}

resource "aws_lambda_function" "campaigns" {
  function_name    = "${var.project}-campaigns"
  role             = var.lab_role_arn
  handler          = "handler.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.campaigns.output_path
  source_code_hash = data.archive_file.campaigns.output_base64sha256
  timeout          = 25
  memory_size      = 512

  environment {
    variables = {
      SM_RDS_CREDENTIALS_ID    = var.rds_secret_name
      SQS_CAMPAIGNS_EVENTS_URL = var.campaign_events_queue_url
      NODE_ENV                 = "production"
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  tags = { Name = "${var.project}-campaigns-lambda" }
}

resource "aws_lambda_function" "reports" {
  function_name    = "${var.project}-reports"
  role             = var.lab_role_arn
  handler          = "handler.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.reports.output_path
  source_code_hash = data.archive_file.reports.output_base64sha256
  timeout          = 25
  memory_size      = 256

  environment {
    variables = {
      DYNAMODB_TABLE       = var.dynamodb_reports_table_name
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
      NODE_ENV             = "production"
    }
  }

  tags = { Name = "${var.project}-reports-lambda" }
}

# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "auth" {
  name              = "/aws/lambda/${var.project}-auth"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "campaigns" {
  name              = "/aws/lambda/${var.project}-campaigns"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "reports" {
  name              = "/aws/lambda/${var.project}-reports"
  retention_in_days = 14
}

# ============================================================
# Lambda Permissions for API Gateway
# ============================================================

resource "aws_lambda_permission" "auth" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "campaigns" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.campaigns.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "reports" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reports.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

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

# ============================================================
# S3 Routes — Root GET / -> S3 index.html
# ============================================================

resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_get_s3" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_rest_api.main.root_resource_id
  http_method             = aws_api_gateway_method.root_get.http_method
  type                    = "AWS"
  integration_http_method = "GET"
  uri                     = "${local.s3_uri_base}/index.html"
  credentials             = var.lab_role_arn
}

resource "aws_api_gateway_method_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"  = true
    "method.response.header.Cache-Control" = true
  }
}

resource "aws_api_gateway_integration_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"  = "integration.response.header.Content-Type"
    "method.response.header.Cache-Control" = "'no-cache'"
  }

  depends_on = [aws_api_gateway_integration.root_get_s3]
}

# --- Error responses for root ---

resource "aws_api_gateway_method_response" "root_get_404" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "404"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "root_get_4xx" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_rest_api.main.root_resource_id
  http_method       = aws_api_gateway_method.root_get.http_method
  status_code       = "404"
  selection_pattern = "4\\d{2}"

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }

  response_templates = {
    "application/json" = "{\"error\": \"Not found\"}"
  }

  depends_on = [aws_api_gateway_integration.root_get_s3]
}

# ============================================================
# S3 Routes — Static assets: GET /static/{proxy+} -> S3
# ============================================================

resource "aws_api_gateway_resource" "static" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "static"
}

resource "aws_api_gateway_resource" "static_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.static.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "static_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.static_proxy.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "static_get_s3" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.static_proxy.id
  http_method             = aws_api_gateway_method.static_get.http_method
  type                    = "AWS"
  integration_http_method = "GET"
  uri                     = "${local.s3_uri_base}/static/{proxy}"
  credentials             = var.lab_role_arn

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_method_response" "static_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.static_proxy.id
  http_method = aws_api_gateway_method.static_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"  = true
    "method.response.header.Cache-Control" = true
  }
}

resource "aws_api_gateway_integration_response" "static_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.static_proxy.id
  http_method = aws_api_gateway_method.static_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"  = "integration.response.header.Content-Type"
    "method.response.header.Cache-Control" = "'public, max-age=86400'"
  }

  depends_on = [aws_api_gateway_integration.static_get_s3]
}

# --- Error responses for static ---

resource "aws_api_gateway_method_response" "static_get_404" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.static_proxy.id
  http_method = aws_api_gateway_method.static_get.http_method
  status_code = "404"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "static_get_4xx" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.static_proxy.id
  http_method       = aws_api_gateway_method.static_get.http_method
  status_code       = "404"
  selection_pattern = "4\\d{2}"

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }

  response_templates = {
    "application/json" = "{\"error\": \"Not found\"}"
  }

  depends_on = [aws_api_gateway_integration.static_get_s3]
}

# ============================================================
# S3 Routes — SvelteKit build assets: GET /_app/{proxy+} -> S3
# ============================================================

resource "aws_api_gateway_resource" "app_assets" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "_app"
}

resource "aws_api_gateway_resource" "app_assets_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.app_assets.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "app_assets_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.app_assets_proxy.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "app_assets_s3" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.app_assets_proxy.id
  http_method             = aws_api_gateway_method.app_assets_get.http_method
  type                    = "AWS"
  integration_http_method = "GET"
  uri                     = "${local.s3_uri_base}/_app/{proxy}"
  credentials             = var.lab_role_arn

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_method_response" "app_assets_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.app_assets_proxy.id
  http_method = aws_api_gateway_method.app_assets_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"  = true
    "method.response.header.Cache-Control" = true
  }
}

resource "aws_api_gateway_integration_response" "app_assets_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.app_assets_proxy.id
  http_method = aws_api_gateway_method.app_assets_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"  = "integration.response.header.Content-Type"
    "method.response.header.Cache-Control" = "'public, max-age=31536000, immutable'"
  }

  depends_on = [aws_api_gateway_integration.app_assets_s3]
}

# 4xx error handling for _app assets (consistent with /static pattern)
resource "aws_api_gateway_method_response" "app_assets_404" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.app_assets_proxy.id
  http_method = aws_api_gateway_method.app_assets_get.http_method
  status_code = "404"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "app_assets_4xx" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.app_assets_proxy.id
  http_method       = aws_api_gateway_method.app_assets_get.http_method
  status_code       = "404"
  selection_pattern = "4\\d{2}"

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }

  response_templates = {
    "application/json" = "{\"error\": \"Not found\"}"
  }

  depends_on = [aws_api_gateway_integration.app_assets_s3]
}

# ============================================================
# S3 Routes — SPA fallback: GET /{proxy+} -> S3 index.html
# ============================================================

resource "aws_api_gateway_resource" "spa_fallback" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "spa_fallback_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.spa_fallback.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "spa_fallback_s3" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.spa_fallback.id
  http_method             = aws_api_gateway_method.spa_fallback_get.http_method
  type                    = "AWS"
  integration_http_method = "GET"
  uri                     = "${local.s3_uri_base}/index.html"
  credentials             = var.lab_role_arn
}

resource "aws_api_gateway_method_response" "spa_fallback_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.spa_fallback.id
  http_method = aws_api_gateway_method.spa_fallback_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"  = true
    "method.response.header.Cache-Control" = true
  }
}

resource "aws_api_gateway_integration_response" "spa_fallback_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.spa_fallback.id
  http_method = aws_api_gateway_method.spa_fallback_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type"  = "'text/html'"
    "method.response.header.Cache-Control" = "'no-cache'"
  }

  depends_on = [aws_api_gateway_integration.spa_fallback_s3]
}

resource "aws_api_gateway_method_response" "spa_fallback_404" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.spa_fallback.id
  http_method = aws_api_gateway_method.spa_fallback_get.http_method
  status_code = "404"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "spa_fallback_4xx" {
  rest_api_id       = aws_api_gateway_rest_api.main.id
  resource_id       = aws_api_gateway_resource.spa_fallback.id
  http_method       = aws_api_gateway_method.spa_fallback_get.http_method
  status_code       = "404"
  selection_pattern = "4\\d{2}"

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
  }

  response_templates = {
    "application/json" = "{\"error\": \"Not found\"}"
  }

  depends_on = [aws_api_gateway_integration.spa_fallback_s3]
}

# ============================================================
# API Routes — Path-based routing to Lambda functions
# ============================================================

# /api resource
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

# --- /api/auth ---

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "auth"
}

resource "aws_api_gateway_method" "auth_any" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.auth.id
  http_method             = aws_api_gateway_method.auth_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.auth.invoke_arn
}

# /api/auth/{proxy+}
resource "aws_api_gateway_resource" "auth_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "auth_proxy_any" {
  rest_api_id        = aws_api_gateway_rest_api.main.id
  resource_id        = aws_api_gateway_resource.auth_proxy.id
  http_method        = "ANY"
  authorization      = "NONE"
  request_parameters = { "method.request.path.proxy" = true }
}

resource "aws_api_gateway_integration" "auth_proxy_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.auth_proxy.id
  http_method             = aws_api_gateway_method.auth_proxy_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.auth.invoke_arn
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

# --- /api/campaigns ---

resource "aws_api_gateway_resource" "campaigns" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "campaigns"
}

resource "aws_api_gateway_method" "campaigns_any" {
  rest_api_id          = aws_api_gateway_rest_api.main.id
  resource_id          = aws_api_gateway_resource.campaigns.id
  http_method          = "ANY"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  authorization_scopes = ["aws.cognito.signin.user.admin"]
}

resource "aws_api_gateway_integration" "campaigns_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.campaigns.id
  http_method             = aws_api_gateway_method.campaigns_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.campaigns.invoke_arn
}

# /api/campaigns/{proxy+}
resource "aws_api_gateway_resource" "campaigns_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.campaigns.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "campaigns_proxy_any" {
  rest_api_id          = aws_api_gateway_rest_api.main.id
  resource_id          = aws_api_gateway_resource.campaigns_proxy.id
  http_method          = "ANY"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  authorization_scopes = ["aws.cognito.signin.user.admin"]
  request_parameters   = { "method.request.path.proxy" = true }
}

resource "aws_api_gateway_integration" "campaigns_proxy_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.campaigns_proxy.id
  http_method             = aws_api_gateway_method.campaigns_proxy_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.campaigns.invoke_arn
}

# --- /api/reports ---

resource "aws_api_gateway_resource" "reports" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "reports"
}

resource "aws_api_gateway_method" "reports_any" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.reports.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "reports_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.reports.id
  http_method             = aws_api_gateway_method.reports_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.reports.invoke_arn
}

# /api/reports/{proxy+}
resource "aws_api_gateway_resource" "reports_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.reports.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "reports_proxy_any" {
  rest_api_id        = aws_api_gateway_rest_api.main.id
  resource_id        = aws_api_gateway_resource.reports_proxy.id
  http_method        = "ANY"
  authorization      = "NONE"
  request_parameters = { "method.request.path.proxy" = true }
}

resource "aws_api_gateway_integration" "reports_proxy_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.reports_proxy.id
  http_method             = aws_api_gateway_method.reports_proxy_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.reports.invoke_arn
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
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = "prod"

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
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = var.lab_role_arn
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
}
