variable "name_prefix" {
  description = "버킷 이름 접두어 (예: jeonbuk)"
  type        = string
}

# 주 버킷 이름을 지정하고 싶을 때 사용(지정 안하면 접두어+랜덤)
variable "bucket_name" {
  description = "주 버킷 이름(옵션, 전역 유니크)"
  type        = string
  default     = ""
}

variable "enable_versioning" {
  description = "주 버킷 버전닝 활성화"
  type        = bool
  default     = true
}

# 주 버킷 라이프사이클(옵션)
variable "lifecycle_enabled" {
  description = "주 버킷 라이프사이클 규칙 활성화 여부"
  type        = bool
  default     = false
}

variable "lifecycle_expiration_days" {
  description = "주 버킷 객체 만료 일수(옵션)"
  type        = number
  default     = 365
}

# 서버 액세스 로깅 옵션
variable "enable_server_access_logging" {
  description = "주 버킷 서버 액세스 로깅 활성화"
  type        = bool
  default     = false
}

# 로그 버킷 이름 직접 지정(미지정 시 prefix-logs-<account_id>)
variable "logs_bucket_name" {
  description = "서버 액세스 로그 수신용 버킷 이름(옵션)"
  type        = string
  default     = ""
}

# 로그 보존 일수
variable "logs_expiration_days" {
  description = "로그 버킷 객체 만료 일수"
  type        = number
  default     = 180
}

variable "force_destroy" {
  description = "비어있지 않아도 버킷 삭제 허용(주의)"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}
