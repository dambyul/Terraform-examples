data "aws_region" "current" {}

locals {
  az_count = length(var.azs)

  # 라우팅에서 사용할 NAT index 선택 (단일 NAT이면 0 고정, 아니면 서브넷 인덱스)
  nat_index = [for i in range(local.az_count) : var.single_nat_gateway ? 0 : i]
}

# ─────────────────────────────
# VPC
# ─────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({
    Name      = "${var.name_prefix}-vpc"
    ManagedBy = "terraform"
  }, var.additional_tags)
}

# ─────────────────────────────
# Internet Gateway
# ─────────────────────────────
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = "${var.name_prefix}-igw" }, var.additional_tags)
}

# ─────────────────────────────
# Subnets
# ─────────────────────────────
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.name_prefix}-public-${count.index}"
    Tier = "public"
  }, var.additional_tags)
}

resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge({
    Name = "${var.name_prefix}-private-app-${count.index}"
    Tier = "private-app"
  }, var.additional_tags)
}

resource "aws_subnet" "private_db" {
  count             = length(var.private_db_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge({
    Name = "${var.name_prefix}-private-db-${count.index}"
    Tier = "private-db"
  }, var.additional_tags)
}

# ─────────────────────────────
# NAT (EIP & NAT GW)
# ─────────────────────────────
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : local.az_count
  domain = "vpc"
  tags   = merge({ Name = "${var.name_prefix}-nat-eip-${count.index}" }, var.additional_tags)
}

resource "aws_nat_gateway" "this" {
  count         = var.single_nat_gateway ? 1 : local.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags       = merge({ Name = "${var.name_prefix}-nat-${count.index}" }, var.additional_tags)
  depends_on = [aws_internet_gateway.this]
}

# ─────────────────────────────
# Route Tables
# ─────────────────────────────
# Public: 0.0.0.0/0 -> IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = "${var.name_prefix}-public-rt" }, var.additional_tags)
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private-App: 0.0.0.0/0 -> NAT
resource "aws_route_table" "private_app" {
  count  = length(aws_subnet.private_app)
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = "${var.name_prefix}-private-app-rt-${count.index}" }, var.additional_tags)
}

resource "aws_route" "private_app_default" {
  count                  = length(aws_route_table.private_app)
  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[local.nat_index[count.index]].id
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# Private-DB: (옵션) 0.0.0.0/0 -> NAT (enable_db_nat=true 일 때만)
resource "aws_route_table" "private_db" {
  count  = length(aws_subnet.private_db)
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = "${var.name_prefix}-private-db-rt-${count.index}" }, var.additional_tags)
}

resource "aws_route" "private_db_default" {
  count                  = var.enable_db_nat ? length(aws_route_table.private_db) : 0
  route_table_id         = aws_route_table.private_db[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[local.nat_index[count.index]].id
}

resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db[count.index].id
}

# ─────────────────────────────
# Interface Endpoints용 SG (443 허용)
#   - vpc_endpoints 모듈에서 사용
# ─────────────────────────────
resource "aws_security_group" "endpoints" {
  name        = "${var.name_prefix}-endpoints-sg"
  description = "Interface VPC Endpoints security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description      = "all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({ Name = "${var.name_prefix}-endpoints-sg" }, var.additional_tags)
}
