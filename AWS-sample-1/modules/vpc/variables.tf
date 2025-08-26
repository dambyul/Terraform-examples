variable "name_prefix" {
  description = "리소스 접두어 (예: jeonbuk)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "azs" {
  description = "사용할 AZ 목록 (예: [\"ap-northeast-2a\",\"ap-northeast-2c\"])"
  type        = list(string)
  validation {
    condition     = length(var.azs) >= 2
    error_message = "최소 2개 AZ를 지정하세요."
  }
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR들 (AZ 개수와 동일한 길이)"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "프라이빗(App) 서브넷 CIDR들 (AZ 개수와 동일한 길이)"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "프라이빗(DB) 서브넷 CIDR들 (AZ 개수와 동일한 길이)"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true면 단일 NAT(GW 1개), false면 AZ별 NAT"
  type        = bool
  default     = true
}

variable "enable_db_nat" {
  description = "DB 서브넷도 NAT 경유 인터넷 아웃바운드 허용 여부"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}
