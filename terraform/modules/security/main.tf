# --- Prefix List Data Sources (region-aware, replaces hardcoded IDs) ---

data "aws_prefix_list" "s3" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${var.region}.s3"]
  }
}

data "aws_prefix_list" "dynamodb" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${var.region}.dynamodb"]
  }
}

# ============================================================
# Frontend Security Group
# ============================================================

resource "aws_security_group" "frontend" {
  name        = "${var.project}-frontend-sg"
  description = "Allows the frontend access to S3, DynamoDB and the Internet."
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project}-frontend-sg" }
}

# -- Inbound --

resource "aws_vpc_security_group_ingress_rule" "frontend_app" {
  security_group_id            = aws_security_group.frontend.id
  description                  = "Allows inbound traffic to port 3000 from ALB"
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "frontend_health" {
  security_group_id            = aws_security_group.frontend.id
  description                  = "Allows inbound health check traffic from ALB"
  from_port                    = 9090
  to_port                      = 9090
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

# -- Outbound --

resource "aws_vpc_security_group_egress_rule" "frontend_dynamodb_http" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allows outbound HTTP to DynamoDB"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.dynamodb.id
}

resource "aws_vpc_security_group_egress_rule" "frontend_dynamodb_https" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allows outbound HTTPS to DynamoDB"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.dynamodb.id
}

resource "aws_vpc_security_group_egress_rule" "frontend_s3_http" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allows outbound HTTP to S3"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "frontend_s3_https" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allows outbound HTTPS to S3"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "frontend_internet_https" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allows outbound HTTPS to the internet (git clone)"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "frontend_dns" {
  security_group_id = aws_security_group.frontend.id
  description       = "Allows outbound DNS (UDP)"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================
# Backend Security Group
# ============================================================

resource "aws_security_group" "backend" {
  name        = "${var.project}-backend-sg"
  description = "Allows the backend access to S3, DynamoDB and the Internet via fck-nat."
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project}-backend-sg" }
}

# No inbound rules — backend is a cron job, not reachable from outside.

# -- Outbound --

resource "aws_vpc_security_group_egress_rule" "backend_dynamodb_http" {
  security_group_id = aws_security_group.backend.id
  description       = "Allows outbound HTTP to DynamoDB"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.dynamodb.id
}

resource "aws_vpc_security_group_egress_rule" "backend_dynamodb_https" {
  security_group_id = aws_security_group.backend.id
  description       = "Allows outbound HTTPS to DynamoDB"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.dynamodb.id
}

resource "aws_vpc_security_group_egress_rule" "backend_s3_http" {
  security_group_id = aws_security_group.backend.id
  description       = "Allows outbound HTTP to S3"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_egress_rule" "backend_s3_https" {
  security_group_id = aws_security_group.backend.id
  description       = "Allows outbound HTTPS to S3"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.s3.id
}

# Internet access through fck-nat — SG evaluates the ACTUAL destination IP (e.g. github.com),
# not the NAT instance IP. So outbound must allow 0.0.0.0/0, not the NAT SG.
resource "aws_vpc_security_group_egress_rule" "backend_internet_http" {
  security_group_id = aws_security_group.backend.id
  description       = "Allows outbound HTTP through fck-nat"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "backend_internet_https" {
  security_group_id = aws_security_group.backend.id
  description       = "Allows outbound HTTPS through fck-nat"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "backend_dns" {
  security_group_id = aws_security_group.backend.id
  description       = "Allows outbound DNS (UDP)"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================
# NAT (fck-nat) Security Group
# ============================================================

resource "aws_security_group" "nat" {
  name        = "${var.project}-nat-sg"
  description = "Allows fck-nat instance to NAT traffic from backend to the Internet."
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project}-nat-sg" }
}

# -- Inbound (from backend) --

resource "aws_vpc_security_group_ingress_rule" "nat_backend_http" {
  security_group_id            = aws_security_group.nat.id
  description                  = "Allows inbound HTTP from backend"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.backend.id
}

resource "aws_vpc_security_group_ingress_rule" "nat_backend_https" {
  security_group_id            = aws_security_group.nat.id
  description                  = "Allows inbound HTTPS from backend"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.backend.id
}

# -- Outbound (to internet) --

resource "aws_vpc_security_group_egress_rule" "nat_http" {
  security_group_id = aws_security_group.nat.id
  description       = "Allows outbound HTTP"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "nat_https" {
  security_group_id = aws_security_group.nat.id
  description       = "Allows outbound HTTPS"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "nat_dns" {
  security_group_id = aws_security_group.nat.id
  description       = "Allows outbound DNS (UDP)"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ============================================================
# ALB Security Group (not in original spec but required by ALB)
# ============================================================

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Allows inbound HTTP to the frontend ALB."
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allows inbound HTTP from the internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_frontend_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allows traffic to frontend app port"
  from_port                    = 3000
  to_port                      = 3000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.frontend.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_frontend_health" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allows health check traffic to frontend"
  from_port                    = 9090
  to_port                      = 9090
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.frontend.id
}
