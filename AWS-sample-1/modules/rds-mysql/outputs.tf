output "id" {
  description = "DB 인스턴스 ID"
  value       = aws_db_instance.this.id
}

output "arn" {
  description = "DB 인스턴스 ARN"
  value       = aws_db_instance.this.arn
}

output "endpoint_address" {
  description = "엔드포인트 주소"
  value       = aws_db_instance.this.address
}

output "endpoint_port" {
  description = "엔드포인트 포트"
  value       = aws_db_instance.this.port
}

output "security_group_id" {
  description = "RDS SG ID"
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "DB Subnet Group 이름"
  value       = aws_db_subnet_group.this.name
}

output "parameter_group_name" {
  description = "DB 파라미터 그룹 이름"
  value       = aws_db_parameter_group.this.name
}
