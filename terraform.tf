#1. Providers Setup (providers.tf)
#This file configures the AWS provider.
provider "aws" {
  region = "us-east-1"  # will choose our preferred AWS region
}

#2. Main File (main.tf)
#This file pulls all the modules together.
module "vpc" {
  source = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24"]
}

module "ec2" {
  source         = "./modules/ec2"
  vpc_id         = module.vpc.vpc_id
  public_subnet  = module.vpc.public_subnets[0]
}

module "rds" {
  source         = "./modules/rds"
  vpc_id         = module.vpc.vpc_id
  private_subnet = module.vpc.private_subnets[0]
}

module "s3" {
  source = "./modules/s3"
  bucket_name = "application-logs-bucket"
}


#3. VPC Module (modules/vpc/main.tf)

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "public" {
  count           = length(var.public_subnets)
  vpc_id          = aws_vpc.main.id
  cidr_block      = var.public_subnets[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count      = length(var.private_subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets[count.index]
}

Variables for VPC (modules/vpc/variables.tf):

variable "cidr_block" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

Outputs for VPC (modules/vpc/outputs.tf):

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

#4. EC2 Module (modules/ec2/main.tf)

resource "aws_security_group" "ec2_sg" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Example AMI, choose one based on region
  instance_type = "t2.micro"
  subnet_id     = var.public_subnet
  security_groups = [aws_security_group.ec2_sg.name]

  tags = {
    Name = "WebServer"
  }
}

Variables for EC2 (modules/ec2/variables.tf):

variable "vpc_id" {
  type = string
}

variable "public_subnet" {
  type = string
}

Outputs for EC2 (modules/ec2/outputs.tf):

output "instance_id" {
  value = aws_instance.web.id
}

#5. RDS Module (modules/rds/main.tf)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [var.private_subnet]
}

resource "aws_db_instance" "rds" {
  identifier              = "rds-instance"
  engine                  = "mysql"
  instance_class          = "db.t2.micro"
  allocated_storage       = 20
  name                    = "mydatabase"
  username                = "admin"
  password                = "password"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [var.vpc_id]
}

Variables for RDS (modules/rds/variables.tf):

variable "vpc_id" {
  type = string
}

variable "private_subnet" {
  type = string
}

Outputs for RDS (modules/rds/outputs.tf):

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}
#6. S3 Module (modules/s3/main.tf)

resource "aws_s3_bucket" "log_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "ApplicationLogs"
  }
}
Variables for S3 (modules/s3/variables.tf):

variable "bucket_name" {
  type = string
}
Outputs for S3 (modules/s3/outputs.tf):

output "bucket_name" {
  value = aws_s3_bucket.log_bucket.id
}

#Running the Script
    #1. Initialize Terraform: In the root directory, run:
       
       terraform init
    #2. Plan the Configuration:
       
       terraform plan
    #3. Apply the Configuration:
       
       terraform apply
