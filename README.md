# ajcl

AJCL Test and Answers:

1. Infrastructure as Code (IaC)

Answer:

Directory Structure for Modularization
First, let's create a structure for the Terraform code to make it modular and reusable.

terraform/
├── main.tf                # Root file to orchestrate modules
├── outputs.tf             # Output information
├── providers.tf           # Cloud provider configuration
├── variables.tf           # Variable definitions
├── modules/
│   ├── vpc/
│   │   ├── main.tf        # VPC resources
│   │   ├── variables.tf   # VPC variables
│   │   └── outputs.tf     # VPC outputs
│   ├── ec2/
│   │   ├── main.tf        # EC2 resources
│   │   ├── variables.tf   # EC2 variables
│   │   └── outputs.tf     # EC2 outputs
│   ├── rds/
│   │   ├── main.tf        # RDS resources
│   │   ├── variables.tf   # RDS variables
│   │   └── outputs.tf     # RDS outputs
│   └── s3/
│       ├── main.tf        # S3 resources
│       ├── variables.tf   # S3 variables
│       └── outputs.tf     # S3 outputs

Step-by-Step Implementation


1. Providers Setup (providers.tf)
This file configures the AWS provider.
provider "aws" {
  region = "us-east-1"  # will choose our preferred AWS region
}

2. Main File (main.tf)
This file pulls all the modules together.
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


3. VPC Module (modules/vpc/main.tf)

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

4. EC2 Module (modules/ec2/main.tf)

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

5. RDS Module (modules/rds/main.tf)
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
6. S3 Module (modules/s3/main.tf)

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

Running the Script
    1. Initialize Terraform: In the root directory, run:
       
       terraform init
    2. Plan the Configuration:
       
       terraform plan
    3. Apply the Configuration:
       
       terraform apply
************************************************************************
2. CI/CD PIPELINE using Git Hub Actions
Answer:
Code:
name: AJCL CICD PIPELINE

on:
  push:
    branches:
      - ajcl  # Trigger on push to the ajcl branch

jobs:
  build:
    name: Build Application
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'

      - name: Install Dependencies
        run: |
          npm install

      - name: Build Frontend
        run: |
          npm run build

      - name: Run Backend Build (Docker)
        run: |
          docker build -t ajcl-app:latest .

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Run Unit and Integration Tests
        run: |
          npm test
          docker-compose -f docker-compose.test.yml up --abort-on-container-exit

  deploy_staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Start SSH agent and add key
        uses: webfactory/ssh-agent@v0.5.3
        with:
          ssh-private-key: ${{ secrets.EC2_SSH_PRIVATE_KEY }}

      - name: Deploy to Staging
        run: |
          ssh -o StrictHostKeyChecking=no -i private_key -p 2221 ubuntu@xxxxxxx '
            docker-compose down
            docker-compose up -d
          '

  approve_production:
    name: Manual Approval for Production
    runs-on: ubuntu-latest
    needs: deploy_staging

    steps:
      - name: Wait for Manual Approval
        uses: hmarr/auto-approve-action@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
        if: github.event.inputs.approved == 'true'

  deploy_production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: approve_production

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Start SSH agent and add key
        uses: webfactory/ssh-agent@v0.5.3
        with:
          ssh-private-key: ${{ secrets.EC2_SSH_PRIVATE_KEY }}

      - name: Deploy to Production
        run: |
          ssh -o StrictHostKeyChecking=no -i private_key -p 2221 ubuntu@xxxxxxx 
            docker-compose down
            docker-compose up -d
          '

  rollback:
    name: Rollback on Failure
    runs-on: ubuntu-latest
    if: failure()
    steps:
      - name: Checkout previous stable version
        uses: actions/checkout@v2

      - name: Start SSH agent and add key
        uses: webfactory/ssh-agent@v0.5.3
        with:
          ssh-private-key: ${{ secrets.EC2_SSH_PRIVATE_KEY }}

      - name: Rollback Deployment
        run: |
          ssh -o StrictHostKeyChecking=no -i private_key -p 2221 ubuntu@xxxxxxx '
            docker-compose down
            docker-compose up -d previous-stable-version
          '
********************************************************************************
3. Configuration Management

1. Install necessary software packages on EC2 instances
Create a playbook that installs required software on your EC2 instances, ensuring idempotency (Ansible only installs packages that aren’t already installed).
---
- name: Install necessary software on EC2 instances
  hosts: webservers
  become: yes

  tasks:
    - name: Ensure Python is installed
      apt:
        name: python3
        state: present
      when: ansible_os_family == "Debian"

    - name: Ensure required packages are installed
      apt:
        name:
          - nginx
          - git
          - python3-pip
        state: present
      when: ansible_os_family == "Debian"

    - name: Ensure Docker is installed
      apt:
        name: docker.io
        state: present

    - name: Ensure Docker is started and enabled
      service:
        name: docker
        state: started
        enabled: yes

2. Configure the application to connect to the RDS instance
In this section, we’ll configure the application to connect to the RDS database. You'll need to supply the database configuration details (like host, username, and password) via environment variables or a configuration file.
---
- name: Configure the application to connect to the RDS instance
  hosts: webservers
  become: yes

  vars:
    db_host: "{{ rds_instance_endpoint }}"
    db_user: "your_db_user"
    db_password: "{{ lookup('env', 'DB_PASSWORD') }}"
    db_name: "your_db_name"

  tasks:
    - name: Copy application configuration file
      template:
        src: templates/app_config.j2
        dest: /etc/myapp/config.ini
        mode: '0644'

    - name: Configure environment variables for database connection
      lineinfile:
        path: /etc/environment
        line: "DB_HOST={{ db_host }} DB_USER={{ db_user }} DB_PASSWORD={{ db_password }} DB_NAME={{ db_name }}"
        create: yes

    - name: Ensure the application service is restarted
      service:
        name: myapp
        state: restarted

Template: templates/app_config.j2
This is a template configuration file for your application:
[database]
host={{ db_host }}
user={{ db_user }}
password={{ db_password }}
name={{ db_name }}

3. Manage environment-specific configurations
You can manage environment-specific configurations by setting different values for variables in separate inventory files for each environment, like staging and production.
Inventory for staging (inventory/staging):

[webservers]
staging-webserver-1 ansible_host=staging-webserver-ip

[rds]
staging-rds-instance ansible_host=staging-rds-endpoint

Inventory for production (inventory/production):

[webservers]
production-webserver-1 ansible_host=production-webserver-ip

[rds]
production-rds-instance ansible_host=production-rds-endpoint

In the playbook, environment-specific variables can be passed using inventory and variable files:

ansible-playbook -i inventory/staging playbooks/configure_application.yml

*****************************************************************
4. Monitoring and Logging

Answer:

Example using Cloud watch

Install CloudWatch Agent

sudo apt update
sudo apt install amazon-cloudwatch-agent
Configure CloudWatch Agent
Create a configuration file for CloudWatch to monitor CPU, memory, and disk usage:

sudo nano /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
Here is an xample configuration for the amazon-cloudwatch-agent.json file:

{
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait"
        ],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "disk_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
Start the CloudWatch Agent

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a start \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s
View CloudWatch Metrics and Set Up Alarms
We will follow these steps
    1. Go to the AWS CloudWatch Console.
    2. Create dashboards and alarms for metrics (e.g., CPU utilization > 80%).

2. ELK Stack (Elasticsearch, Logstash, Kibana) Setup on Ubuntu
Step 1: Install Java (required for Elasticsearch and Logstash)
We will follow below steps to set up ELK

sudo apt update
sudo apt install openjdk-11-jdk -y
java -version
Step 2: Install Elasticsearch

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

sudo apt update
sudo apt install elasticsearch
Configure Elasticsearch to start automatically on boot:

sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
Step 3: Install Logstash

sudo apt install logstash
Example configuration for Logstash (/etc/logstash/conf.d/logstash.conf):

sudo nano /etc/logstash/conf.d/logstash.conf
Add the following:

input {
  file {
    path => "/var/log/app/*.log"
    start_position => "beginning"
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
}

output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "app-logs-%{+YYYY.MM.dd}"
  }
}
Start Logstash:

sudo systemctl start logstash
sudo systemctl enable logstash
Step 4: Install Kibana

sudo apt install kibana
Configure Kibana to start automatically and run it:

sudo systemctl enable kibana
sudo systemctl start kibana
Access Kibana on http://<your-server-ip>:5601.
