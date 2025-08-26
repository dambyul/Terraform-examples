data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  resource_name = "${var.name_prefix}-mysql"
  pg_family     = startswith(var.engine_version, "8.4.") ? "mysql8.4" : "mysql8.0"
}

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${local.resource_name}-subnets"
  subnet_ids = var.subnet_ids
  tags       = merge({ Name = "${local.resource_name}-subnets" }, var.additional_tags)
}

# RDS SG (인바운드: allowed_sg_ids에서만 3306 허용)
resource "aws_security_group" "this" {
  name        = "${local.resource_name}-sg"
  description = "RDS MySQL SG"
  vpc_id      = var.vpc_id

  # 인바운드: 소스 SG 참조
  dynamic "ingress" {
    for_each = toset(var.allowed_sg_ids)
    content {
      description     = "MySQL from ${ingress.value}"
      from_port       = var.port
      to_port         = var.port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # 아웃바운드(기본 허용)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({ Name = "${local.resource_name}-sg" }, var.additional_tags)
}

# 파라미터 그룹 (family 자동 매칭)
resource "aws_db_parameter_group" "this" {
  name   = "${local.resource_name}-pg"
  family = local.pg_family
  tags   = merge({ Name = "${local.resource_name}-pg" }, var.additional_tags)

  dynamic "parameter" {
    for_each = var.parameter_overrides
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

# 실제 RDS 인스턴스
resource "aws_db_instance" "this" {
  # Engine
  identifier = "${local.resource_name}"
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Network
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = var.publicly_accessible
  port                   = var.port

  # Storage
  allocated_storage = var.allocated_storage_gb
  storage_type      = var.storage_type
  iops              = var.iops
  storage_encrypted = var.storage_encrypted

  # Credentials
  username = var.username
  password = var.password

  # Ops
  multi_az                     = var.multi_az
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  backup_retention_period      = var.backup_retention_period
  backup_window       = var.preferred_backup_window
  maintenance_window  = var.preferred_maintenance_window
  apply_immediately            = var.apply_immediately
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.final_snapshot_identifier

  # Auth/Monitoring
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  performance_insights_enabled        = var.performance_insights_enabled

  # Param group
  parameter_group_name = aws_db_parameter_group.this.name

  # Tags
  tags = merge({
    Name      = local.resource_name
    ManagedBy = "terraform"
    Engine    = "mysql"
    Version   = var.engine_version
  }, var.additional_tags)
}
