terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "your-profile"

  default_tags {
    tags = local.common_tags
  }
}