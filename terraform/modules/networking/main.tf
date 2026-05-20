# --- VPC ---

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project}-vpc" }
}

# --- Subnets ---

locals {
  subnets = {
    backend-az1 = { cidr = cidrsubnet(var.vpc_cidr, 8, 2), az = "${var.region}a" }
    backend-az2 = { cidr = cidrsubnet(var.vpc_cidr, 8, 5), az = "${var.region}b" }
  }
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = { Name = "${var.project}-${each.key}" }
}

# --- Route Tables ---

resource "aws_route_table" "backend_az1" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-backend-rtb-az1" }
}

resource "aws_route_table" "backend_az2" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-backend-rtb-az2" }
}

# --- Route Table Associations ---

resource "aws_route_table_association" "backend_az1" {
  subnet_id      = aws_subnet.this["backend-az1"].id
  route_table_id = aws_route_table.backend_az1.id
}

resource "aws_route_table_association" "backend_az2" {
  subnet_id      = aws_subnet.this["backend-az2"].id
  route_table_id = aws_route_table.backend_az2.id
}

# --- Security Groups ---

resource "aws_security_group" "lambda" {
  name        = "${var.project}-lambda-sg"
  description = "Campaigns Lambda: outbound to RDS and VPC endpoints"
  vpc_id      = aws_vpc.main.id

  egress {
    description     = "PostgreSQL to RDS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
  }

  egress {
    description     = "HTTPS to VPC endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.endpoint.id]
  }

  tags = { Name = "${var.project}-lambda-sg" }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "RDS: inbound from Lambda only"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-rds-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_lambda" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from Lambda"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lambda.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_proxy" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from RDS Proxy (self-referencing)"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_egress_rule" "rds_to_endpoints" {
  security_group_id            = aws_security_group.rds.id
  description                  = "HTTPS to VPC endpoints (Secrets Manager credential retrieval)"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.endpoint.id
}

resource "aws_vpc_security_group_egress_rule" "proxy_to_rds" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from RDS Proxy to DB instance (self-referencing)"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_security_group" "endpoint" {
  name        = "${var.project}-endpoint-sg"
  description = "VPC endpoints: inbound HTTPS from Lambda"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-endpoint-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_from_lambda" {
  security_group_id            = aws_security_group.endpoint.id
  description                  = "HTTPS from Lambda"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lambda.id
}

resource "aws_vpc_security_group_ingress_rule" "endpoint_from_rds" {
  security_group_id            = aws_security_group.endpoint.id
  description                  = "HTTPS from RDS Proxy (Secrets Manager credential retrieval)"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

# --- VPC Gateway Endpoints (free) ---

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.backend_az1.id,
    aws_route_table.backend_az2.id,
  ]

  tags = { Name = "${var.project}-s3-endpoint" }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.backend_az1.id,
    aws_route_table.backend_az2.id,
  ]

  tags = { Name = "${var.project}-dynamodb-endpoint" }
}

# --- VPC Interface Endpoints ---

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.this["backend-az1"].id]
  security_group_ids  = [aws_security_group.endpoint.id]
  tags                = { Name = "${var.project}-sqs-endpoint" }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.this["backend-az1"].id]
  security_group_ids  = [aws_security_group.endpoint.id]
  tags                = { Name = "${var.project}-secretsmanager-endpoint" }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.this["backend-az1"].id]
  security_group_ids  = [aws_security_group.endpoint.id]
  tags                = { Name = "${var.project}-logs-endpoint" }
}
