locals {
  stub_handler   = "export const handler = async (event) => ({ statusCode: 200, headers: {\"Content-Type\": \"application/json\"}, body: JSON.stringify({ message: \"stub\" }) });"
  pkg_json_esm   = "{\"type\":\"module\"}"
  lambda_runtime = "nodejs22.x"
  node_env       = "production"

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
  runtime          = local.lambda_runtime
  handler          = "handler.handler"
  filename         = data.archive_file.auth.output_path
  source_code_hash = data.archive_file.auth.output_base64sha256
  timeout          = 10
  memory_size      = 256

  environment {
    variables = {
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
      NODE_ENV             = local.node_env
    }
  }

  tags = { Name = "${var.project}-auth-lambda" }

  depends_on = [aws_cloudwatch_log_group.auth]
}

resource "aws_lambda_function" "campaigns" {
  function_name    = "${var.project}-campaigns"
  role             = var.lab_role_arn
  runtime          = local.lambda_runtime
  handler          = "handler.handler"
  filename         = data.archive_file.campaigns.output_path
  source_code_hash = data.archive_file.campaigns.output_base64sha256
  timeout          = 25
  memory_size      = 512

  environment {
    variables = {
      SM_RDS_CREDENTIALS_ID    = var.rds_secret_name
      SQS_CAMPAIGNS_EVENTS_URL = var.campaign_events_queue_url
      NODE_ENV                 = local.node_env
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  tags = { Name = "${var.project}-campaigns-lambda" }

  depends_on = [aws_cloudwatch_log_group.campaigns]
}

resource "aws_lambda_function" "reports" {
  function_name    = "${var.project}-reports"
  role             = var.lab_role_arn
  runtime          = local.lambda_runtime
  handler          = "handler.handler"
  filename         = data.archive_file.reports.output_path
  source_code_hash = data.archive_file.reports.output_base64sha256
  timeout          = 25
  memory_size      = 256

  environment {
    variables = {
      DYNAMODB_TABLE       = var.dynamodb_reports_table_name
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
      NODE_ENV             = local.node_env
    }
  }

  tags = { Name = "${var.project}-reports-lambda" }

  depends_on = [aws_cloudwatch_log_group.reports]
}

# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "auth" {
  name              = "/aws/lambda/${var.project}-auth"
  retention_in_days = 14
  tags              = { Name = "${var.project}-auth-logs" }
}

resource "aws_cloudwatch_log_group" "campaigns" {
  name              = "/aws/lambda/${var.project}-campaigns"
  retention_in_days = 14
  tags              = { Name = "${var.project}-campaigns-logs" }
}

resource "aws_cloudwatch_log_group" "reports" {
  name              = "/aws/lambda/${var.project}-reports"
  retention_in_days = 14
  tags              = { Name = "${var.project}-reports-logs" }
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
