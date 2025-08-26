data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  region = data.aws_region.current.id
  account_id = data.aws_caller_identity.current.account_id

  final_logs_bucket_name = var.logs_bucket_name != "" ? var.logs_bucket_name : lower("${var.name_prefix}-logs-${local.account_id}")
}

# 전역 유니크 보장을 위한 랜덤 suffix (bucket_name 미지정 시 사용)
resource "random_id" "suffix" {
  keepers = {
    name_prefix = var.name_prefix
  }
  byte_length = 3
}

# ─────────────────────────────
# 주 버킷
# ─────────────────────────────
resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name != "" ? var.bucket_name : lower("${var.name_prefix}-${random_id.suffix.hex}")
  force_destroy = var.force_destroy

  tags = merge({
    Name      = var.bucket_name != "" ? var.bucket_name : "${var.name_prefix}-${random_id.suffix.hex}"
    ManagedBy = "terraform"
  }, var.additional_tags)
}

# 퍼블릭 차단
resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 소유권(ACL 사용 안 함 기본)
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 버전닝
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# SSE (AES256 기본 / KMS 선택)
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 라이프사이클(옵션)
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "expire-objects"
    status = "Enabled"
    filter {}
    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}

# ─────────────────────────────
# 서버 액세스 로깅 (옵션)
#   - 수신 로그 버킷은 ACL 필요 → Ownership: BucketOwnerPreferred + ACL log-delivery-write
# ─────────────────────────────
resource "aws_s3_bucket" "logs" {
  count         = var.enable_server_access_logging ? 1 : 0
  bucket        = local.final_logs_bucket_name
  force_destroy = var.force_destroy

  tags = merge({
    Name      = local.final_logs_bucket_name
    ManagedBy = "terraform"
    Purpose   = "server-access-logs"
  }, var.additional_tags)
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count                   = var.enable_server_access_logging ? 1 : 0
  bucket                  = aws_s3_bucket.logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 로그 수신 버킷: ACL 사용 가능해야 함
resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.enable_server_access_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# 로그 수신 버킷: log-delivery-write ACL
resource "aws_s3_bucket_acl" "logs" {
  count      = var.enable_server_access_logging ? 1 : 0
  bucket     = aws_s3_bucket.logs[0].id
  acl        = "log-delivery-write"
  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# 로그 버킷 버전닝 + SSE + 라이프사이클
resource "aws_s3_bucket_versioning" "logs" {
  count  = var.enable_server_access_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.enable_server_access_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = var.enable_server_access_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = var.logs_expiration_days
    }
  }
}

# 주 버킷 → 로그 버킷으로 서버 액세스 로깅 연결
resource "aws_s3_bucket_logging" "main" {
  count  = var.enable_server_access_logging ? 1 : 0
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "s3-access/${aws_s3_bucket.main.bucket}/"
}
