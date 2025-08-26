variable "name_prefix" {
  description = "리소스 접두어 (예: jeonbuk)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "DB Subnet Group에 넣을 프라이빗(DB) 서브넷들"
  type        = list(string)
}

variable "allocated_storage_gb" {
  description = "초기 스토리지(GB)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "스토리지 타입"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.storage_type)
    error_message = "storage_type은 gp3/gp2/io1/io2 중 하나여야 함."
  }
}

variable "iops" {
  description = "별도 IOPS (gp3/io1/io2에서 사용)"
  type        = number
  default     = null
}

variable "engine_version" {
  description = "MySQL 엔진 버전 (예: 8.0.36, 8.4.5)"
  type        = string
  default     = "8.4.5"
  validation {
    condition     = can(regex("^8\\.(0|4)\\.[0-9]+$", var.engine_version))
    error_message = "MySQL 8.0.x 또는 8.4.x 형식으로 지정하세요. 예) 8.4.5"
  }
}

variable "instance_class" {
  description = "DB 인스턴스 클래스 (예: db.m7g.large)"
  type        = string
  default     = "db.m7g.large"
}

variable "multi_az" {
  description = "Multi-AZ 배포 여부"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "퍼블릭 접근 허용 여부(보통 false)"
  type        = bool
  default     = false
}

variable "username" {
  description = "마스터 사용자명"
  type        = string
  default     = "admin"
  validation {
    condition     = length(var.username) >= 1 && length(var.username) <= 16
    error_message = "사용자명은 1~16자."
  }
}

variable "password" {
  description = "마스터 패스워드"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "MySQL 포트"
  type        = number
  default     = 3306
}

variable "backup_retention_period" {
  description = "백업 보존일(0=미사용)"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "백업 윈도우 (예: 18:00-19:00)"
  type        = string
  default     = null
}

variable "preferred_maintenance_window" {
  description = "점검 윈도우 (예: Sun:19:00-Sun:20:00)"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "즉시 적용 여부(업데이트 시 재시작 유발 가능)"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "마이너 자동 업그레이드"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "삭제 보호"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "삭제 시 최종 스냅샷 생략"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "최종 스냅샷 ID(생략하지 않을 때 필요)"
  type        = string
  default     = null
}

variable "parameter_overrides" {
  description = "DB 파라미터 key=value 맵 (예: { character_set_server = \"utf8mb4\" })"
  type        = map(string)
  default     = {}
}

variable "iam_database_authentication_enabled" {
  description = "IAM DB 인증 사용"
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "performance_insights_enabled" {
  description = "PI 활성화"
  type        = bool
  default     = false
}

variable "allowed_sg_ids" {
  description = "접속 허용 소스 SG들 (bastion/airflow SG 전달)"
  type        = list(string)
  default     = []
}

variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}
