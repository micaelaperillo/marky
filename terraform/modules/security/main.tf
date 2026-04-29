# --- Prefix List Data Sources ---

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
# Backend Security Group
# ============================================================

resource "aws_security_group" "backend" {
  name        = "${var.project}-backend-sg"
  description = "Allows the backend cron access to S3, DynamoDB and the Internet via fck-nat."
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project}-backend-sg" }
}

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
