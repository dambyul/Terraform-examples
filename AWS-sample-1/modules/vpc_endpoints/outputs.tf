output "s3_gateway_endpoint_id" {
  description = "S3 Gateway VPC Endpoint ID (생성 시)"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "interface_endpoint_ids" {
  description = "생성된 인터페이스 엔드포인트 ID 맵 (key => id)"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_service_names" {
  description = "생성된 인터페이스 엔드포인트 서비스 이름 맵 (key => service name)"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.service_name }
}
