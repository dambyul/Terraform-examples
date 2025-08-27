# Terraform 기반 AWS 구축 스크립트

이 리포지토리는 **서울 리전(ap-northeast-2)**에 운영용 인프라를 구성함.

- VPC: Public/App/DB 서브넷, IGW, 단일 NAT Gateway
- VPC Endpoints:
    - Gateway: S3
    - Interface: ECR API, ECR DKR, Logs, SSM, Secrets Manager, EC2 Messages, SSM Messages
- KMS Keys: RDS, Logs용
- RDS MySQL (gp3, 암호화, Multi-AZ=false, deletion_protection=true)
- EC2
    - Bastion (t4g.micro, Amazon Linux 2023, EIP 할당됨, SG는 특정 IP에서만 22포트 허용)
    - Airflow Host (r7g.large, Ubuntu 22.04 arm64, 프라이빗 서브넷에 위치, SG는 Bastion SG에서만 SSH 및 포트 31000 허용)
- Elastic IP

## 아키텍처
![AWS Architecture](https://github.com/dambyul/Terraform-examples/blob/AWS-sample-1/AWS-sample-1/aws-example-1.png)
- Apache Airflow는 EC2 인스턴스와 RDS, S3 사이의 연결을 위해 표시한 것으로 별도로 설치 및 구성이 필요

## Quick start
```bash
cd envs/prod
terraform fmt -recursive
terraform init
terraform validate
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

## 가이드
- Bastion을 통해 Airflow Host 및 RDS 접근 가능
- Airflow Host는 프라이빗 서브넷에 배치 → 외부 접근은 Bastion 통해서만 가능
- 보안 그룹은 최소 허용:
    - 특정 IP → Bastion (SSH)
    - Bastion → Airflow (SSH, 포트 31000)
- 모든 EBS는 KMS 암호화 적용
- RDS는 삭제 보호 활성화됨 → 삭제 시 deletion_protection = false로 변경 필요
