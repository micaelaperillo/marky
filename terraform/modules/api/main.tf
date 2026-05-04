data "aws_caller_identity" "current" {}

locals {
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  s3_uri_base  = "arn:aws:apigateway:${var.region}:s3:path/${var.frontend_bucket_name}"
}

# ============================================================
# Lambda Function
# ============================================================

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/dist/lambda.zip"
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.project}-api"
  role             = local.lab_role_arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 29

  environment {
    variables = {
      BACKEND_URL    = var.backend_url
      COOKIE_SECRET  = var.cookie_secret
      DYNAMODB_TABLE = "${var.project}-data"
      NODE_ENV       = "production"
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  tags = { Name = "${var.project}-api-lambda" }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# ============================================================
# API Gateway REST API
# ============================================================

resource "aws_api_gateway_rest_api" "main" {
  name               = "${var.project}-api"
  binary_media_types = ["image/*", "font/*", "application/wasm", "application/octet-stream"]

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = { Name = "${var.project}-api" }
}

# --- Root resource: GET / → S3 index.html ---

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
  credentials             = local.lab_role_arn
}

resource "aws_api_gateway_method_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
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

# --- Static assets: GET /static/{proxy+} → S3 ---

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
  credentials             = local.lab_role_arn

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
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "static_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.static_proxy.id
  http_method = aws_api_gateway_method.static_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
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

# --- API routes: ANY /api/{proxy+} → Lambda ---

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "api_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "api_any" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.api_proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "api_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.api_proxy.id
  http_method             = aws_api_gateway_method.api_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.api.invoke_arn
}

# --- SvelteKit build assets: GET /_app/{proxy+} → S3 ---

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
  credentials             = local.lab_role_arn

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
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "app_assets_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.app_assets_proxy.id
  http_method = aws_api_gateway_method.app_assets_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
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

# --- SPA fallback: GET /{proxy+} → S3 index.html ---

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
  credentials             = local.lab_role_arn
}

resource "aws_api_gateway_method_response" "spa_fallback_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.spa_fallback.id
  http_method = aws_api_gateway_method.spa_fallback_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "spa_fallback_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.spa_fallback.id
  http_method = aws_api_gateway_method.spa_fallback_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = "'text/html'"
  }

  depends_on = [aws_api_gateway_integration.spa_fallback_s3]
}

# --- Deployment + Stage ---

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      # Root → S3 index.html
      aws_api_gateway_method.root_get,
      aws_api_gateway_integration.root_get_s3,
      aws_api_gateway_method_response.root_get_200,
      aws_api_gateway_method_response.root_get_404,
      aws_api_gateway_integration_response.root_get_200,
      aws_api_gateway_integration_response.root_get_4xx,
      # Static assets → S3
      aws_api_gateway_method.static_get,
      aws_api_gateway_integration.static_get_s3,
      aws_api_gateway_method_response.static_get_200,
      aws_api_gateway_method_response.static_get_404,
      aws_api_gateway_integration_response.static_get_200,
      aws_api_gateway_integration_response.static_get_4xx,
      # _app build assets → S3
      aws_api_gateway_method.app_assets_get,
      aws_api_gateway_integration.app_assets_s3,
      aws_api_gateway_method_response.app_assets_200,
      aws_api_gateway_method_response.app_assets_404,
      aws_api_gateway_integration_response.app_assets_200,
      aws_api_gateway_integration_response.app_assets_4xx,
      # API → Lambda
      aws_api_gateway_method.api_any,
      aws_api_gateway_integration.api_lambda,
      # SPA fallback → S3 index.html
      aws_api_gateway_method.spa_fallback_get,
      aws_api_gateway_integration.spa_fallback_s3,
      aws_api_gateway_method_response.spa_fallback_200,
      aws_api_gateway_integration_response.spa_fallback_200,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration_response.root_get_200,
    aws_api_gateway_integration_response.static_get_200,
    aws_api_gateway_integration_response.app_assets_200,
    aws_api_gateway_integration.api_lambda,
    aws_api_gateway_integration_response.spa_fallback_200,
  ]
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = "prod"

  tags = { Name = "${var.project}-api-stage" }
}
