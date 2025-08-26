output "enabled" {
  value       = var.enabled
  description = "모듈 활성화 여부"
}

output "cgw_id" {
  value       = try(aws_customer_gateway.this[0].id, null)
  description = "Customer Gateway ID"
}

output "vgw_id" {
  value       = try(aws_vpn_gateway.this[0].id, null)
  description = "Virtual Private Gateway ID"
}

output "vpn_connection_id" {
  value       = try(aws_vpn_connection.this[0].id, null)
  description = "VPN Connection ID"
}

# 터널 정보 (생성 시에만 값 존재)
output "tunnel1_address" {
  value       = try(aws_vpn_connection.this[0].tunnel1_address, null)
  description = "터널1 AWS 공인 IP"
}

output "tunnel2_address" {
  value       = try(aws_vpn_connection.this[0].tunnel2_address, null)
  description = "터널2 AWS 공인 IP"
}

output "tunnel1_preshared_key" {
  value       = try(aws_vpn_connection.this[0].tunnel1_preshared_key, null)
  description = "터널1 PSK"
  sensitive   = true
}

output "tunnel2_preshared_key" {
  value       = try(aws_vpn_connection.this[0].tunnel2_preshared_key, null)
  description = "터널2 PSK"
  sensitive   = true
}

output "tunnel1_inside_cidr" {
  value       = try(aws_vpn_connection.this[0].tunnel1_inside_cidr, null)
  description = "터널1 내부 CIDR (/30)"
}

output "tunnel2_inside_cidr" {
  value       = try(aws_vpn_connection.this[0].tunnel2_inside_cidr, null)
  description = "터널2 내부 CIDR (/30)"
}

output "is_static_routing" {
  value       = length(var.static_routes) > 0
  description = "정적 라우팅 사용 여부"
}
