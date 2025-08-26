aws_region = "ap-northeast-2"

project     = "your-param"
env         = "prod"
name_prefix = "your-param"

default_tags = {
  Project = "your-param"
  Env     = "prod"
}

vpc_cidr = "10.10.0.0/16"
azs      = ["ap-northeast-2a", "ap-northeast-2c"]

# AWS 키페어 생성 후 할당
bastion_key_pair_name = "your-bastion-key" 
airflow_key_pair_name = "your-airflow-key"

public_subnet_cidrs      = ["10.10.0.0/24", "10.10.1.0/24"]
private_app_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
private_db_subnet_cidrs  = ["10.10.20.0/24", "10.10.21.0/24"]

rds_allocated_storage_gb = 500
rds_engine_version       = "8.4.5"
rds_instance_class       = "db.m7g.xlarge"
rds_username             = "admin"
rds_password             = "your-password"

# Bastion
bastion_allow_ssh_cidrs = ["0.0.0.0/0"]

# VPN (optional)
vpn_enabled = false
# vpn_customer_gateway_ip = "0.0.0.0"
# vpn_customer_bgp_asn    = 65000
