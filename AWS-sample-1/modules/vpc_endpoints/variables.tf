variable "vpc_id" {
  description = "대상 VPC ID"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "인터페이스 엔드포인트를 둘 서브넷 IDs (일반적으로 프라이빗 App 서브넷)"
  type        = list(string)
}

variable "private_app_route_table_ids" {
  description = "게이트웨이(S3) 엔드포인트를 연결할 라우트 테이블 IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "인터페이스 엔드포인트용 SG (예: VPC CIDR로 443 허용)"
  type        = string
}

variable "create_gateway_endpoints" {
  description = "게이트웨이 엔드포인트(S3) 생성 여부"
  type        = bool
  default     = true
}

variable "interface_endpoints" {
  description = <<EOT
생성할 인터페이스 엔드포인트의 키 목록:
- logs, ssm, secretsmanager, ec2messages, ssmmessages
EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for e in var.interface_endpoints :
      contains(
        ["logs", "ssm", "secretsmanager", "ec2messages", "ssmmessages"],
        e
      )
    ])
    error_message = "interface_endpoints 값은 logs, ssm, secretsmanager, ec2messages, ssmmessages 중에서만 선택하세요."
  }
}

variable "private_dns_enabled" {
  description = "인터페이스 엔드포인트 Private DNS 활성화 여부"
  type        = bool
  default     = true
}

variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}
