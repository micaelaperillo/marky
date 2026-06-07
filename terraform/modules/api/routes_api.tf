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
