###############################################
# Environment wiring for Jeonbuk prod
###############################################

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# ─────────────── VPC ───────────────
module "vpc" {
  source = "../../modules/vpc"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  azs                      = var.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  single_nat_gateway       = true
  enable_db_nat            = false
}

# ─────────────── VPC Endpoints (NAT 비용 최소화) ───────────────
module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  vpc_id                      = module.vpc.vpc_id
  private_app_subnet_ids      = module.vpc.private_app_subnet_ids
  security_group_id           = module.vpc.endpoint_sg_id
  private_app_route_table_ids = module.vpc.private_app_route_table_ids

  create_gateway_endpoints = true
  interface_endpoints = [
    "logs",
    "ssm",
    "secretsmanager",
    "ec2messages",
    "ssmmessages"
  ]
}

# ─────────────── EC2용 IAM Role / Instance Profile ───────────────
# 공통 신뢰 정책
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Bastion: SSM
resource "aws_iam_role" "bastion" {
  name               = "${local.name_prefix}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# Airflow: SSM ReadOnly
resource "aws_iam_role" "airflow" {
  name               = "${local.name_prefix}-airflow-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
resource "aws_iam_role_policy_attachment" "airflow_ssm" {
  role       = aws_iam_role.airflow.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "airflow" {
  name = "${local.name_prefix}-airflow-profile"
  role = aws_iam_role.airflow.name
}

# ─────────────── Bastion (퍼블릭) ───────────────
module "ec2_bastion" {
  source        = "../../modules/ec2-instance"
  name          = "${local.name_prefix}-bastion"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  instance_type = "t4g.micro"

  associate_public_ip = true
  create_eip          = true

  allow_ssh         = true
  ingress_ssh_cidrs = var.bastion_allow_ssh_cidrs

  # 비용 절감
  monitoring = false

  # 루트에서 만든 프로파일 지정
  iam_instance_profile_name = aws_iam_instance_profile.bastion.name

  # 필요 시 기존 키페어 사용
  key_pair_name = var.bastion_key_pair_name
}

# ─────────────── Airflow Host (프라이빗) ───────────────
module "ec2_airflow" {
  source        = "../../modules/ec2-instance"
  name          = "${local.name_prefix}-airflow"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.private_app_subnet_ids[0]
  instance_type = "r7g.large"

  associate_public_ip = false

  # 디스크 200GB
  volume_size_gb = 200

  # 비용 절감
  monitoring = false

  iam_instance_profile_name = aws_iam_instance_profile.airflow.name

  # 필요 시
  key_pair_name = var.airflow_key_pair_name
}

# bastion → airflow: SSH(22)
resource "aws_security_group_rule" "airflow_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = module.ec2_airflow.security_group_id
  source_security_group_id = module.ec2_bastion.security_group_id
}

# bastion → airflow: Airflow UI(31000 프록시)
resource "aws_security_group_rule" "airflow_ui_from_bastion" {
  type                     = "ingress"
  from_port                = 31000
  to_port                  = 31000
  protocol                 = "tcp"
  security_group_id        = module.ec2_airflow.security_group_id
  source_security_group_id = module.ec2_bastion.security_group_id
}

# ─────────────── RDS MySQL ───────────────
module "rds" {
  source = "../../modules/rds-mysql"

  name_prefix          = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_db_subnet_ids
  storage_encrypted    = true
  allocated_storage_gb = var.rds_allocated_storage_gb
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  multi_az             = false

  username = var.rds_username
  password = var.rds_password

  # 접근 허용 SG (출력명 변경: sg_id → security_group_id)
  allowed_sg_ids = [
    module.ec2_airflow.security_group_id,
    module.ec2_bastion.security_group_id,
  ]
}

# ─────────────── S3 (예: 로그/공유 버킷) ───────────────
module "s3_bucket" {
  source      = "../../modules/s3"
  name_prefix = local.name_prefix
}

# ─────────────── (옵션) Site-to-Site VPN ───────────────
module "vpn" {
  source = "../../modules/vpn"

  enabled                 = var.vpn_enabled
  vpc_id                  = module.vpc.vpc_id
  private_route_table_ids = module.vpc.private_app_route_table_ids
  customer_gateway_ip     = var.vpn_customer_gateway_ip
  customer_bgp_asn        = var.vpn_customer_bgp_asn
  aws_bgp_asn             = 64512
}
