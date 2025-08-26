output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_app_subnet_ids" { value = module.vpc.private_app_subnet_ids }
output "private_db_subnet_ids" { value = module.vpc.private_db_subnet_ids }

output "rds_endpoint" {
  value = module.rds.endpoint_address
}

output "rds_sg_id" {
  value = module.rds.security_group_id
}

output "rds_port" {
  value = module.rds.endpoint_port
}

output "bastion_instance_id" { value = module.ec2_bastion.instance_id }
output "airflow_instance_id" { value = module.ec2_airflow.instance_id }
