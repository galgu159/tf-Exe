terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.16"
    }
  }

  required_version = ">= 1.2.0"
  backend "s3" {
    bucket = "galgu-tf-state-files"
    key    = "tfstate.json"
    region = "eu-north-1"
    # optional: dynamodb_table = "<table-name>"
  }
}

provider "aws" {
  region = var.region
  # profile = "<aws-course-profile>"
}

# IAM Role for EC2
resource "aws_iam_role" "app_server_role" {
  name               = "galgu-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "app_server_instance_profile" {
  name = "galgu-instance-profile"
  role = aws_iam_role.app_server_role.name
}

# Key pair resource
resource "aws_key_pair" "my_key_pair" {
  key_name   = "galgu-key-irland"
  public_key = file(var.my_key_pair)
}

# Security group resource
resource "aws_security_group" "app_server_sg" {
  name        = "galgu-sg"   # change <your-name> accordingly
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance resource
resource "aws_instance" "app_server" {
  ami                  = var.ami_id
  instance_type        = "t3.micro"
  security_groups      = [aws_security_group.app_server_sg.name]
  key_name             = aws_key_pair.my_key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.app_server_instance_profile.name  # Attach IAM instance profile
  # user_data = file("./deploy.sh")

  tags = {
    Name      = "galgu-tf-${var.env}"
    Terraform = "true"
    testtag   = "blablabla"
  }

  # Ensure the instance creation waits for the IAM role and security group to be created
  depends_on = [
    aws_iam_instance_profile.app_server_instance_profile,
    aws_security_group.app_server_sg,
  ]
}
