# ============================================================
# S3 Routes — Root GET / -> S3 index.html
# ============================================================

locals {
  s3_uri_base = "arn:aws:apigateway:${var.region}:s3:path/${var.frontend_bucket_name}"
}

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
