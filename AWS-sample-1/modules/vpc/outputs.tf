output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "vpc_cidr_block" {
  value       = aws_vpc.this.cidr_block
  description = "VPC CIDR"
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "퍼블릭 서브넷 IDs"
}

output "private_app_subnet_ids" {
  value       = [for s in aws_subnet.private_app : s.id]
  description = "프라이빗(App) 서브넷 IDs"
}

output "private_db_subnet_ids" {
  value       = [for s in aws_subnet.private_db : s.id]
  description = "프라이빗(DB) 서브넷 IDs"
}

output "private_app_route_table_ids" {
  value       = [for rt in aws_route_table.private_app : rt.id]
  description = "프라이빗(App) 라우트 테이블 IDs"
}

output "endpoint_sg_id" {
  value       = aws_security_group.endpoints.id
  description = "Interface Endpoints용 SG ID"
}
