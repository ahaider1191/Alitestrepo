terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
access_key = "AKIA3U4TD2JNTPHIZCXI"
secret_key = "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"
region = "us-east-1"
}

variable "ec2_ami" {
  type = string
  default = "ami-002070d43b0a4f171"
  description = "Centos 7 AMI variable"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
  description = "EC2 configuration type"
}

variable "cidr" {
  type = string
  default = "10.0.0.0/16"
  description = "cidr block for VPC and subnet"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "alis-project-bucket"
  tags = {
    Name = "Alis Project Bucket"
  }
}

resource "aws_vpc" "main" {
  cidr_block       = var.cidr
  enable_dns_hostnames = true

  tags = {
    Name = "Alis Project VPC"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "Alis Project Subnet"
  }
}

resource "aws_internet_gateway" "my_vpc_igw" {
  vpc_id     = aws_vpc.main.id

  tags = {
    Name = "My VPC - Internet Gateway"
  }
}

resource "aws_route_table" "my_vpc_us_east_1a_public" {
    vpc_id     = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_vpc_igw.id
    }

    tags = {
        Name = "Public Subnet Route Table."
    }
}

resource "aws_route_table_association" "my_vpc_us_east_1a_public" {
    subnet_id     = aws_subnet.main.id
    route_table_id = aws_route_table.my_vpc_us_east_1a_public.id
}

resource "aws_key_pair" "deployer" {
  key_name   = "id_rsa.pub"
  public_key ="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCbcnBxlqYncnL576roSCkbRd8fMLY3WejLdBl1o3wNbFrxbwUSgeJ3II8f995XlAKcK6uZ71cs89NNO6oCTDt1hC6Gtt5coAt95XmwOu/r3H/Cm7QB7OpvZIQm6o7bHwvP7Dq6LafluPmvNDPWMhPtMwdCBeSdDasd2B2/j52u0ogdlZLSzcbbeb5KidvdDunNxkiApViefYeRyf3cNLqyztBYFQ3e4y3JlraFwmZXViV8KisIGUoHrTrV0X+PQUohQXdS6xp4q3ujtnHarL51sZjRmDdmzhD0ru/i+8ws5JzldYi7s9PDjNEF8Rqfh+dD/wqxStkfFnkO0lqOuCYwQVEA+9a3ivtx1SvNucaTEOe/7PBcLxSQfyC0QA8Az8Tz+3kUC6KDMIKTZYDg5Xg3DbtrBWgdr7U0h3pznxm2OblFJ/8gTq/h1kCGOmh8KeGSy/XWQCNeIuQ+4XA2OZReIZOaFCQT33lv8J3jaAHAaN14+hSKDZn4bLEtG9vYrXk= alihaider@Alis-MBP"
}

resource "aws_security_group" "main" {
    vpc_id     = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_sg"
  }
}

resource "aws_instance" "master_server" {
  ami           = var.ec2_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id
  key_name = "id_rsa.pub"
  vpc_security_group_ids = [aws_security_group.main.id]
  associate_public_ip_address = true
  count = 1

  tags = {
    Name = "Ansible Master"
  }
}

resource "aws_instance" "slave_servers" {
  ami           = var.ec2_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id
  key_name = "id_rsa.pub"
  vpc_security_group_ids = [aws_security_group.main.id]
  associate_public_ip_address = true
  count = 3

  tags = {
    Name = "Ansible Slave ${count.index +1}"
  }
}