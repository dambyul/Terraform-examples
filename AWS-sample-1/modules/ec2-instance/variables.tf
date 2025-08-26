variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "associate_public_ip" {
  type    = bool
  default = false
}

variable "create_eip" {
  type    = bool
  default = false
}

variable "allow_ssh" {
  type    = bool
  default = false
}

variable "ingress_ssh_cidrs" {
  type    = list(string)
  default = []
}

# 상세 모니터링 (비용 절감용 기본 false)
variable "monitoring" {
  type    = bool
  default = false
}

# 디스크
variable "volume_size_gb" {
  type    = number
  default = 30
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "volume_iops" {
  type    = number
  default = 3000
}

variable "volume_throughput" {
  type    = number
  default = 125
}

# 루트에서 만든 Instance Profile을 직접 넘길 때 사용
variable "iam_instance_profile_name" {
  type    = string
  default = ""
}

# 기존 키페어 사용 시
variable "key_pair_name" {
  type    = string
  default = ""
}

# (선택) 추가 태그
variable "additional_tags" {
  type    = map(string)
  default = {}
}

# (선택) (과거 호환) 모듈 내부에서 롤 만들 때 붙일 정책 – 지금 구성에선 안 씁니다
variable "extra_iam_policies" {
  type    = list(string)
  default = []
}

variable "ami_id" {
  description = "Optional AMI ID to override the default (Ubuntu ARM64). Leave empty to use the default."
  type        = string
  default     = ""
}