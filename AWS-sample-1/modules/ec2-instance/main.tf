locals {
  # Graviton(t4g/r7g/m7g/c7g 등)이면 arm64, 아니면 x86_64
  arch = can(regex("^([ctgr]6|m7)g\\.", var.instance_type)) ? "arm64" : "x86_64"
}

data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-*"]
  }

  filter {
    name   = "architecture"
    values = [local.arch]
  }
}

data "aws_ami" "ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu 공식 계정)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Default SG for ${var.name}"
  vpc_id      = var.vpc_id

  # egress all
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "all egress"
  }

  # SSH 허용 (필요 시에만)
  dynamic "ingress" {
    for_each = var.allow_ssh ? var.ingress_ssh_cidrs : []
    content {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [ingress.value]
      ipv6_cidr_blocks = []
    }
  }

  tags = merge({ Name = "${var.name}-sg" }, var.additional_tags)
}

resource "aws_instance" "this" {
  ami                         = coalesce(var.ami_id, data.aws_ami.ubuntu_arm64.id)
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = var.associate_public_ip

  # 상세 모니터링 (false면 비용 절감)
  monitoring = var.monitoring

  # 키페어: 값이 있으면 사용
  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  # 루트에서 만든 인스턴스 프로파일을 직접 부착
  iam_instance_profile = var.iam_instance_profile_name != "" ? var.iam_instance_profile_name : null

  # 루트 디스크
  root_block_device {
    volume_size = var.volume_size_gb
    volume_type = var.volume_type
    iops        = var.volume_type == "gp3" ? var.volume_iops       : null
    throughput  = var.volume_type == "gp3" ? var.volume_throughput : null
    encrypted   = true
  }

  tags = merge({ Name = var.name }, var.additional_tags)
}

# 선택: EIP 고정 IP 필요 시
resource "aws_eip" "this" {
  count = var.associate_public_ip && var.create_eip ? 1 : 0
  domain = "vpc"
  tags  = merge({ Name = "${var.name}-eip" }, var.additional_tags)
}

resource "aws_eip_association" "this" {
  count         = var.associate_public_ip && var.create_eip ? 1 : 0
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}
