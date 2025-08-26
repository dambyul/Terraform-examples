locals {
  is_enabled = var.enabled
  is_static  = length(var.static_routes) > 0
}

# ─────────────────────────────
# Customer Gateway (온프레 공인 IP, BGP ASN)
# ─────────────────────────────
resource "aws_customer_gateway" "this" {
  count      = local.is_enabled ? 1 : 0
  bgp_asn    = var.customer_bgp_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = merge({
    Name      = "cgw"
    ManagedBy = "terraform"
  }, var.additional_tags)
}

# ─────────────────────────────
# Virtual Private Gateway (VGW) + VPC 연결
# ─────────────────────────────
resource "aws_vpn_gateway" "this" {
  count           = local.is_enabled ? 1 : 0
  vpc_id          = var.vpc_id
  amazon_side_asn = var.aws_bgp_asn

  tags = merge({
    Name      = "vgw"
    ManagedBy = "terraform"
  }, var.additional_tags)
}

# (신규 VPC에 붙을 때는 별도 attachment 리소스 없이 위 vpc_id 지정으로 충분)

# ─────────────────────────────
# VPN 연결 (2개 터널)
#  - BGP: static_routes_only = false
#  - 정적: static_routes_only = true + aws_vpn_connection_route
# ─────────────────────────────
resource "aws_vpn_connection" "this" {
  count               = local.is_enabled ? 1 : 0
  customer_gateway_id = aws_customer_gateway.this[0].id
  vpn_gateway_id      = aws_vpn_gateway.this[0].id
  type                = "ipsec.1"
  static_routes_only  = local.is_static

  # (옵션) 터널 내부 CIDR 지정
  tunnel1_inside_cidr = var.tunnel1_inside_cidr
  tunnel2_inside_cidr = var.tunnel2_inside_cidr

  tags = merge({
    Name      = "s2s-vpn"
    ManagedBy = "terraform"
  }, var.additional_tags)
}

# 정적 라우팅일 경우, 대상 CIDR 등록
resource "aws_vpn_connection_route" "static" {
  for_each               = local.is_enabled && local.is_static ? toset(var.static_routes) : []
  vpn_connection_id      = aws_vpn_connection.this[0].id
  destination_cidr_block = each.value
}

# BGP(동적) 라우팅일 경우, VGW 경로 전파를 프라이빗 RT들에 활성화
resource "aws_vpn_gateway_route_propagation" "propagate" {
  for_each       = local.is_enabled && !local.is_static ? toset(var.private_route_table_ids) : []
  vpn_gateway_id = aws_vpn_gateway.this[0].id
  route_table_id = each.value
}
