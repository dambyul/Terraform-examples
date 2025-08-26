variable "enabled" {
  description = "VPN 생성/비활성화 스위치"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "대상 VPC ID"
  type        = string
}

variable "private_route_table_ids" {
  description = "VPN 경로 전파를 설정할 프라이빗 라우트 테이블 IDs"
  type        = list(string)
}

variable "customer_gateway_ip" {
  description = "온프레미스(고객) 게이트웨이의 공인 IP (정적)"
  type        = string
  default     = ""
  validation {
    condition     = var.customer_gateway_ip == "" || can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", var.customer_gateway_ip))
    error_message = "customer_gateway_ip 는 유효한 IPv4 주소여야 합니다."
  }
}

variable "customer_bgp_asn" {
  description = "고객 게이트웨이 BGP ASN (동적 라우팅 시 사용)"
  type        = number
  default     = 65000
}

variable "aws_bgp_asn" {
  description = "AWS 측(VPN Gateway) BGP ASN"
  type        = number
  default     = 64512
}

variable "static_routes" {
  description = "정적 라우팅 대상 CIDR 목록 (비우면 BGP 사용)"
  type        = list(string)
  default     = []
}

# (옵션) 터널 내부 CIDR (/30, 169.254.0.0/16 권장 대역)
variable "tunnel1_inside_cidr" {
  type    = string
  default = null
}

variable "tunnel2_inside_cidr" {
  type    = string
  default = null
}

variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}
