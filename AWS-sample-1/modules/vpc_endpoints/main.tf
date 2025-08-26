data "aws_region" "current" {}

locals {
  region = data.aws_region.current.id   # ← name → id
  interface_service_map = {
    "logs"           = "com.amazonaws.${local.region}.logs"
    "ssm"            = "com.amazonaws.${local.region}.ssm"
    "secretsmanager" = "com.amazonaws.${local.region}.secretsmanager"
    "ec2messages"    = "com.amazonaws.${local.region}.ec2messages"
    "ssmmessages"    = "com.amazonaws.${local.region}.ssmmessages"
  }

  # 유효 키만 필터링하여 {key=service_name} 맵 구성
  selected_interfaces = {
    for k in distinct(var.interface_endpoints) :
    k => local.interface_service_map[k]
    if contains(keys(local.interface_service_map), k)
  }
}

# ─────────────────────────────────────────
# Gateway Endpoint: S3 (요청대로 S3만 생성)
# ─────────────────────────────────────────
resource "aws_vpc_endpoint" "s3" {
  count             = var.create_gateway_endpoints ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_app_route_table_ids

  tags = merge({ Name = "vpce-s3" }, var.additional_tags)
}

# ─────────────────────────────────────────
# Interface Endpoints (선택 생성)
# ─────────────────────────────────────────
resource "aws_vpc_endpoint" "interface" {
  for_each            = local.selected_interfaces
  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_app_subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = var.private_dns_enabled

  tags = merge({ Name = "vpce-${each.key}" }, var.additional_tags)
}
