locals {
  # 환경별 접두어 구성: jeonbuk-prod
  name_prefix = var.name_prefix
  env         = var.env

  resource_prefix = "${local.name_prefix}-${local.env}"

  common_tags = merge(
    {
      Project   = var.project
      Env       = local.env
      ManagedBy = "terraform"
    },
    var.default_tags
  )
}
