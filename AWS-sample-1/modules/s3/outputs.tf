output "bucket_name" {
  value       = aws_s3_bucket.main.bucket
  description = "주 버킷 이름"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "주 버킷 ARN"
}

output "logs_bucket_name" {
  value       = try(aws_s3_bucket.logs[0].bucket, null)
  description = "서버 액세스 로그 버킷 이름(활성화 시)"
}

output "logs_bucket_arn" {
  value       = try(aws_s3_bucket.logs[0].arn, null)
  description = "서버 액세스 로그 버킷 ARN(활성화 시)"
}
