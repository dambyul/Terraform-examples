# 공용
variable "project" {
  type        = string
  description = "프로젝트명 태그 값"
  default     = "jeonbuk"
}

variable "env" {
  type        = string
  description = "환경명"
  default     = "prod"
  validation {
    condition     = contains(["dev", "stage", "stg", "prod"], lower(var.env))
    error_message = "env는 dev/stage/stg/prod 중 하나여야 합니다."
  }
}

variable "name_prefix" {
  type        = string
  description = "리소스 이름 접두어 (예: jeonbuk)"
  default     = "jeonbuk"
}

variable "aws_region" {
  type        = string
  description = "AWS 리전"
}

variable "default_tags" {
  type        = map(string)
  description = "모든 리소스에 공통 적용할 추가 태그"
  default     = {}
}

# VPC / Subnets
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "azs" {
  type        = list(string)
  description = "사용할 AZ 목록"
  validation {
    condition     = length(var.azs) >= 2
    error_message = "최소 2개 AZ를 지정하세요."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "퍼블릭 서브넷 CIDR들"
  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "퍼블릭 서브넷 개수는 AZ 개수와 동일해야 합니다."
  }
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "프라이빗(App) 서브넷 CIDR들"
  validation {
    condition     = length(var.private_app_subnet_cidrs) == length(var.azs)
    error_message = "App 서브넷 개수는 AZ 개수와 동일해야 합니다."
  }
}

variable "private_db_subnet_cidrs" {
  type        = list(string)
  description = "프라이빗(DB) 서브넷 CIDR들"
  validation {
    condition     = length(var.private_db_subnet_cidrs) == length(var.azs)
    error_message = "DB 서브넷 개수는 AZ 개수와 동일해야 합니다."
  }
}

# RDS
variable "rds_allocated_storage_gb" {
  type        = number
  description = "RDS 스토리지(GB)"
  default     = 100
  validation {
    condition     = var.rds_allocated_storage_gb >= 20
    error_message = "RDS 스토리지는 최소 20GB 이상이어야 합니다."
  }
}

variable "rds_engine_version" {
  type        = string
  description = "MySQL 엔진 버전 (예: 8.0.36, 8.4.5)"
  default     = "8.4.5"
  validation {
    condition     = can(regex("^8\\.(0|4)\\.[0-9]+$", var.rds_engine_version))
    error_message = "MySQL 8.0.x 또는 8.4.x 형식으로 지정하세요. 예) 8.4.5"
  }
}

variable "rds_instance_class" {
  type        = string
  description = "RDS 인스턴스 클래스"
  default     = "db.m7g.large"
  validation {
    condition     = can(regex("^db\\.[cmrtpg]\\d.*", var.rds_instance_class))
    error_message = "유효한 RDS 인스턴스 클래스를 입력하세요 (예: db.m7g.large)."
  }
}

variable "rds_username" {
  type        = string
  description = "RDS 관리자 계정"
  default     = "admin"
  validation {
    condition     = length(var.rds_username) >= 1 && length(var.rds_username) <= 16
    error_message = "RDS 사용자명은 1~16자여야 합니다."
  }
}

variable "rds_password" {
  type        = string
  description = "RDS 비밀번호 (환경변수 TF_VAR_rds_password로 주입 권장)"
  sensitive   = true
}

variable "bastion_allow_ssh_cidrs" {
  type        = list(string)
  description = "배스천 SSH 허용 CIDR"
  default     = []
  validation {
    condition     = alltrue([for c in var.bastion_allow_ssh_cidrs : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", c))])
    error_message = "올바른 CIDR 표기만 허용됩니다. 예) 1.2.3.4/32"
  }
}

# VPN (옵션)
variable "vpn_enabled" {
  type        = bool
  description = "Site-to-Site VPN 활성화 여부"
  default     = false
}

variable "vpn_customer_gateway_ip" {
  type        = string
  description = "고객 게이트웨이 공인 IP"
  default     = ""
}

variable "vpn_customer_bgp_asn" {
  type        = number
  description = "고객 BGP ASN"
  default     = 65000
}

variable "bastion_key_pair_name" {
  type    = string
  default = ""
}
variable "airflow_key_pair_name" {
  type    = string
  default = ""
}