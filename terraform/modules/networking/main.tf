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
    nat-az1     = { cidr = "172.16.3.0/24", az = "${var.region}a" }
    nat-az2     = { cidr = "172.16.6.0/24", az = "${var.region}b" }
    backend-az1 = { cidr = "172.16.2.0/24", az = "${var.region}a" }
    backend-az2 = { cidr = "172.16.5.0/24", az = "${var.region}b" }
  }
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = { Name = "${var.project}-${each.key}" }
}

# --- Internet Gateway ---

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project}-igw" }
}

# --- Route Tables ---

resource "aws_route_table" "nat_az1" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-nat-rtb-az1" }
}

resource "aws_route_table" "nat_az2" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-nat-rtb-az2" }
}

resource "aws_route_table" "backend_az1" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-backend-rtb-az1" }
}

resource "aws_route_table" "backend_az2" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-backend-rtb-az2" }
}

# --- IGW Routes (NAT subnets only) ---

resource "aws_route" "nat_az1_igw" {
  route_table_id         = aws_route_table.nat_az1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "nat_az2_igw" {
  route_table_id         = aws_route_table.nat_az2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Backend route tables: NO IGW. NAT module injects 0.0.0.0/0 → fck-nat.

# --- Route Table Associations ---

resource "aws_route_table_association" "nat_az1" {
  subnet_id      = aws_subnet.this["nat-az1"].id
  route_table_id = aws_route_table.nat_az1.id
}

resource "aws_route_table_association" "nat_az2" {
  subnet_id      = aws_subnet.this["nat-az2"].id
  route_table_id = aws_route_table.nat_az2.id
}

resource "aws_route_table_association" "backend_az1" {
  subnet_id      = aws_subnet.this["backend-az1"].id
  route_table_id = aws_route_table.backend_az1.id
}

resource "aws_route_table_association" "backend_az2" {
  subnet_id      = aws_subnet.this["backend-az2"].id
  route_table_id = aws_route_table.backend_az2.id
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
