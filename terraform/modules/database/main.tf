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
  identifier     = "${var.project}-db"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.db_instance_class

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

  tags = {
    Name = "${var.project}-db"
  }
}

resource "aws_db_proxy" "main" {
  name          = "${var.project}-db-proxy"
  engine_family = "POSTGRESQL"
  role_arn      = var.lab_role_arn

  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = [var.rds_sg_id]
  require_tls            = true

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
    max_connections_percent = 90
  }
}

resource "aws_db_proxy_target" "main" {
  db_proxy_name          = aws_db_proxy.main.name
  target_group_name      = aws_db_proxy_default_target_group.main.name
  db_instance_identifier = aws_db_instance.main.identifier
}

resource "aws_dynamodb_table" "reports" {
  name         = "${var.project}-reports"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "campaign_id"
  range_key    = "timestamp"

  attribute {
    name = "campaign_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
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
