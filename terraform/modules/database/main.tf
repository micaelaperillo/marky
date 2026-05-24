resource "random_password" "rds_master" {
  length           = 32
  special          = true
  override_special = "!#$%&*-_=+?"

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.project}-rds-credentials-${var.suffix}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds_master.result
    dbname   = var.db_name
    engine   = "postgres"
    port     = 5432
    host     = aws_db_proxy.main.endpoint
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier                 = "${var.project}-db"
  engine                     = "postgres"
  engine_version             = "16"
  auto_minor_version_upgrade = false
  instance_class             = var.db_instance_class
  parameter_group_name       = aws_db_parameter_group.main.name

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.rds_master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true

  backup_retention_period = 7
  apply_immediately       = true
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  tags = {
    Name = "${var.project}-db"
  }

  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.project}-db-params"
  family = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "5000"
  }

  parameter {
    name  = "statement_timeout"
    value = "10000"
  }

  tags = { Name = "${var.project}-db-params" }
}

resource "aws_db_proxy" "main" {
  name          = "${var.project}-db-proxy"
  engine_family = "POSTGRESQL"
  role_arn      = var.lab_role_arn

  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = [var.rds_sg_id]
  require_tls            = true
  idle_client_timeout    = 600

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_credentials.arn
  }

  tags = {
    Name = "${var.project}-db-proxy"
  }
}

resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    max_connections_percent      = 70
    max_idle_connections_percent = 30
    connection_borrow_timeout    = 20
    session_pinning_filters      = ["EXCLUDE_VARIABLE_SETS"]
  }
}

resource "aws_db_proxy_target" "main" {
  db_proxy_name          = aws_db_proxy.main.name
  target_group_name      = aws_db_proxy_default_target_group.main.name
  db_instance_identifier = aws_db_instance.main.identifier

  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
}

# ============================================================
# DB Migrator Lambda
# ============================================================

locals {
  stub_handler = "export const handler = async () => ({ success: false, message: \"stub\" });"
  pkg_json_esm = "{\"type\":\"module\"}"
}

data "archive_file" "migrator" {
  type        = "zip"
  output_path = "${path.module}/dist/migrator.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/migrator/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }

  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

resource "aws_cloudwatch_log_group" "migrator" {
  name              = "/aws/lambda/${var.project}-migrator"
  retention_in_days = 7
}

resource "aws_lambda_function" "migrator" {
  function_name    = "${var.project}-migrator"
  role             = var.lab_role_arn
  runtime          = "nodejs22.x"
  handler          = "handler.handler"
  filename         = data.archive_file.migrator.output_path
  source_code_hash = data.archive_file.migrator.output_base64sha256
  timeout          = 60

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      SM_RDS_CREDENTIALS_ID = aws_secretsmanager_secret.rds_credentials.name
      NODE_ENV              = "production"
    }
  }

  depends_on = [aws_cloudwatch_log_group.migrator]
}

resource "time_sleep" "wait_for_proxy" {
  depends_on      = [aws_db_proxy_target.main]
  create_duration = "8m"
}

resource "aws_lambda_invocation" "migrate" {
  function_name = aws_lambda_function.migrator.function_name
  input         = jsonencode({ action = "migrate" })

  triggers = {
    rerun = sha256(aws_lambda_function.migrator.source_code_hash)
  }

  depends_on = [time_sleep.wait_for_proxy]
}

resource "aws_dynamodb_table" "reports" {
  name         = "${var.project}-reports"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project}-reports"
  }
}
