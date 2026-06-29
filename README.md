# Title: 3-Tier Infrastructure Deployment Using Terraform Modules

## **Objective:**

Design and deploy a complete 3-tier web application architecture on AWS using
Terraform modules and automation tools like Ansible or Terraform provisioners.
Project Requirements:

### Terraform code:

- **Tree structure**

```bash
terraform
│   .terraform.lock.hcl
│   hosts.ini
│   main.tf
│   outputs.tf
│   variables.tf
│   
├───.terraform
│   │   terraform.tfstate
│   │   
│   ├───modules
│   │       modules.json
│   │       
│   └───providers
│       └───registry.terraform.io
│           └───hashicorp
│               ├───aws
│               │   └───6.49.0
│               │       └───windows_amd64
│               │               LICENSE.txt
│               │               terraform-provider-aws_v6.49.0_x5.exe
│               │               
│               └───local
│                   └───2.9.0
│                       └───windows_amd64
│                               LICENSE.txt
│                               terraform-provider-local_v2.9.0_x5.exe
│                               
└───module
    ├───ec2
    │       main.tf
    │       outputs.tf
    │       variables.tf
    │       
    ├───rds
    │       main.tf
    │       outputs.tf
    │       variables.tf
    │       
    └───vpc
            main.tf
            outputs.tf
            variables.tf
```

- Terraform main files
    - main.tf
    
    ```bash
    terraform {
        backend "s3"{
            bucket = "cloudstudent-terraform-state-bucket"
            region = "ap-south-1"
            key = "global/s3/terraform.tfstate"
            dynamodb_table = "cloudstudent-terraform-locks"        
            encrypt        = true
            use_lockfile = true
        }
    }
     
     # Define provider and resources
    provider "aws" {
        region = var.region
    }
    
    module "vpc" {
      source = "./module/vpc"
      VPC-name       = var.root_vpc_name
      vpc-cidr-block = var.root_vpc_cidr_block
    }
    
    module "ec2" {
      source = "./module/ec2"
      
      vpc_id               = module.vpc.VPC-ID
      vpc_cidr_block       = var.root_vpc_cidr_block
      public_subnet_1a_id  = module.vpc.public_subnet_1a_id
      public_subnet_1b_id  = module.vpc.public_subnet_1b_id
      private_subnet_2a_id = module.vpc.private_subnet_2a_id
      private_subnet_2b_id = module.vpc.private_subnet_2b_id
      
      VPC-name             = var.root_vpc_name
      ami                  = var.root_ami
      instance_type        = var.root_instance_type
      key_name             = var.root_key_name
    }
    
    module "rds" {
      source = "./module/rds"
      
      db_subnet_group_name = module.vpc.db_subnet_group_name
      db_security_group_id = module.ec2.db_sg_id
      
      VPC-name             = var.root_vpc_name
    }
    
    resource "local_file" "ansible_inventory" {
      filename = "./inventory.ini"
    
      content = <<EOT
    [web]
    web_server_1a ansible_host=${module.ec2.public-ip-1a}
    web_server_1b ansible_host=${module.ec2.public-ip-1b}
    
    [app]
    app_server_2a ansible_host=${module.ec2.private-ip-2a}
    app_server_2b ansible_host=${module.ec2.private-ip-2b}
    EOT
    }
    ```
    
    *(Added a resource, where main.tf file will automatically create inventory.ini file.)*
    
    - variables.tf
    
    ```bash
    variable "region" {
      default     = "ap-south-1"
    }
    
    variable "root_vpc_name" {
      default     = "cloudstudent"
    }
    
    variable "root_vpc_cidr_block" {
      default     = "10.0.0.0/16"
    }
    
    variable "root_ami" {
      default     = "ami-07a00cf47dbbc844c"
    }
    
    variable "root_instance_type" {
      default     = "t3.micro"
    }
    
    variable "root_key_name" {
      default     = "cloudstudent"
    }
    ```
    
    - outputs.tf
    
    ```bash
    
    output "root_vpc_id" {
      value       = module.vpc.VPC-ID
    }
    
    output "web_server_1a_public_ip" {
      value       = module.ec2.public-ip-1a
    }
    
    output "web_server_1b_public_ip" {
      value       = module.ec2.public-ip-1b
    }
    
    output "app_server_2a_private_ip" {
      value       = module.ec2.private-ip-2a
    }
    
    output "app_server_2b_private_ip" {
      value       = module.ec2.private-ip-2b
    }
    
    output "database_endpoint" {
      value       = module.rds.rds_instance_endpoint
    }
    ```
    
- modules/
    - EC2
        - main.tf
        
        ```bash
        # Create sg for web tier
        resource "aws_security_group" "tf-web-security-group" {
            name        = "allow http,https,ssh traffic"
          description = "Allow HTTP,SSH,HTTPS traffic"
          vpc_id      = var.vpc_id
        
          tags = {
            Name = "${var.VPC-name}-web-security-group"
          }
        }  
        
        resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4-web" {
          security_group_id = aws_security_group.tf-web-security-group.id
          cidr_ipv4         = "${var.all-traffic}"
          from_port         = 80
          ip_protocol       = "tcp"
          to_port           = 80
        }
        
        resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4-web" {
          security_group_id = aws_security_group.tf-web-security-group.id
          cidr_ipv4         = "${var.all-traffic}"
          from_port         = 22
          ip_protocol       = "tcp"
          to_port           = 22
        }
        
        resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-web" {
          security_group_id = aws_security_group.tf-web-security-group.id
          cidr_ipv4         = "${var.all-traffic}"
          ip_protocol       = "-1" # semantically equivalent to all ports
        }
        
        # Create sg for app tier
        resource "aws_security_group" "tf-app-security-group" {
            name        = "allow http traffic from web tier"
          description = "Allow HTTP traffic from web tier only"
          vpc_id      = var.vpc_id
        
          tags = {
            Name = "${var.VPC-name}-app-security-group"
          }
        }
         
        resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4-app" {
          security_group_id = aws_security_group.tf-app-security-group.id
          referenced_security_group_id = aws_security_group.tf-web-security-group.id
          from_port         = 80
          ip_protocol       = "tcp"
          to_port           = 80
        }
        
        resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4-app" {
          security_group_id = aws_security_group.tf-app-security-group.id
          referenced_security_group_id = aws_security_group.tf-web-security-group.id
          from_port         = 22
          ip_protocol       = "tcp"
          to_port           = 22
        }
        
        resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-app" {
          security_group_id = aws_security_group.tf-app-security-group.id
          cidr_ipv4         = "${var.all-traffic}"
          ip_protocol       = "-1" # semantically equivalent to all ports
        }
        
        # Create sg for db tier
        resource "aws_security_group" "tf-db-security-group" {
            name        = "allow mysql traffic from app tier"
          description = "Allow mysql traffic from app tier only"
          vpc_id      = var.vpc_id
        
          tags = {
            Name = "${var.VPC-name}-db-security-group"
          }
        }
        
        resource "aws_vpc_security_group_ingress_rule" "allow_mysql_ipv4-db" {
          security_group_id = aws_security_group.tf-db-security-group.id
          referenced_security_group_id = aws_security_group.tf-app-security-group.id
          from_port         = 3306
          ip_protocol       = "tcp"
          to_port           = 3306
        }
        
        resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-db" {
          security_group_id = aws_security_group.tf-db-security-group.id
          cidr_ipv4         = "${var.all-traffic}"
          ip_protocol       = "-1" # semantically equivalent to all ports
        }
        
        # Create EC2
        ## creating web server
        resource "aws_instance" "tf-web-public-1a" {
          tags = {
            Name = "${var.VPC-name}-web-1a"
          }
          ami = "${var.ami}"
          instance_type = "${var.instance_type}"
          vpc_security_group_ids = [aws_security_group.tf-web-security-group.id]
          key_name = "${var.key_name}"
          subnet_id = var.public_subnet_1a_id
          associate_public_ip_address = true
        }
        
        resource "aws_instance" "tf-web-public-1b"{
            tags = {
            Name = "${var.VPC-name}-web-1b"
          }
          ami = "${var.ami}"
          instance_type = "${var.instance_type}"
          vpc_security_group_ids = [aws_security_group.tf-web-security-group.id]
          key_name = "${var.key_name}"
          subnet_id = var.public_subnet_1b_id
          associate_public_ip_address = true
        }
        
        ## create app server
        resource "aws_instance" "tf-app-private-2a"{
          tags = {
            Name = "${var.VPC-name}-app-2a"
          }
          ami = "${var.ami}"
          instance_type = "${var.instance_type}"
          vpc_security_group_ids = [aws_security_group.tf-app-security-group.id]
          key_name = "${var.key_name}"
          subnet_id = var.private_subnet_2a_id
          associate_public_ip_address = false
        }
        
        resource "aws_instance" "tf-app-private-2b"{
            tags = {
            Name = "${var.VPC-name}-app-2b"
          }
          ami = "${var.ami}"
          instance_type = "${var.instance_type}"
          vpc_security_group_ids = [aws_security_group.tf-app-security-group.id]
          key_name = "${var.key_name}"
          subnet_id = var.private_subnet_2b_id
          associate_public_ip_address = false
        }
        ```
        
        - variables.tf
        
        ```bash
        variable "all-traffic" {
            default = "0.0.0.0/0"
        }
        
        variable "VPC-name" {
          default     = "cloudstudent"
        }
        
        variable "instance_type" {
            default = "t3.micro"
        }
        
        variable "key_name" {
            default = "cloudstudent"
        }
        
        variable "ami" {
            default = "ami-07a00cf47dbbc844c"
        }
        
        variable "vpc_id" { 
            type = string
        }
        
        variable "vpc_cidr_block" { 
            type = string 
        }
        
        variable "public_subnet_1a_id" { 
            type = string 
        }
        
        variable "public_subnet_1b_id" { 
            type = string 
        }
        
        variable "private_subnet_2a_id" { 
            type = string 
        }
        
        variable "private_subnet_2b_id" { 
            type = string 
        }
        ```
        
        - outputs.tf
        
        ```bash
        output "web_sg_id" {
          value = aws_security_group.tf-web-security-group.id
        }
        
        output "app_sg_id" {
          value = aws_security_group.tf-app-security-group.id
        }
        
        output "db_sg_id" {
          value = aws_security_group.tf-db-security-group.id
        }
        
        # define output block to print ips on termminal
        output "public-ip-1a" {
          value = aws_instance.tf-web-public-1a.public_ip
        }
        
        output "public-ip-1b" {
          value = aws_instance.tf-web-public-1b.public_ip
        }
        
        output "private-ip-2a" {
          value = aws_instance.tf-app-private-2a.private_ip
        }
        
        output "private-ip-2b" {
          value = aws_instance.tf-app-private-2b.private_ip
        }
        ```
        
    - RDS
        - main.tf
        
        ```bash
        # Create RDS Instance
        resource "aws_db_instance" "cloudstudent_db" {
          allocated_storage      = 20                  
          max_allocated_storage  = 20                  
          engine                 = "${var.engine}"
          engine_version         = "${var.engine_version}"
          instance_class         = "${var.instance_class}"        
          db_name                = "${var.db_name}"
          username               = "${var.username}"
          password               = "${var.password}"
          vpc_security_group_ids = [var.db_security_group_id]
          db_subnet_group_name   = var.db_subnet_group_name
          multi_az               = false                
          availability_zone      = "${var.availability_zone}"
          skip_final_snapshot    = true                
          publicly_accessible    = false                
          tags = {
            Name = "${var.VPC-name}-single-RDS"
          }
          final_snapshot_identifier = null
        }
        ```
        
        - variables.tf
        
        ```bash
        variable "VPC-name" {
            default = "cloudstudent"
        }
        
        variable "db_name" {
            default = "student_db"
        }
        
        variable "username" {
            default = "admin"
        }
        
        variable "password" {
            default = "cloudstudent123"
            sensitive = true
        }
        
        variable "availability_zone" {
            default = "ap-south-1a"
        }
        
        variable "engine" {
            default = "mysql"
        }
        
        variable "engine_version"{
            default = "8.0"
        }
        
        variable "instance_class" {
            default = "db.t3.micro"
        }
        
        variable "db_security_group_id" { 
            type = string 
        
        }
        
        variable "db_subnet_group_name" { 
            type = string 
        }
        ```
        
        - outputs.tf
        
        ```bash
        output "rds_instance_endpoint" {
          value       = aws_db_instance.cloudstudent_db.endpoint
        }
        
        output "rds_instance_id" {
          value       = aws_db_instance.cloudstudent_db.id
        }
        
        output "rds_instance_arn" {
          value       = aws_db_instance.cloudstudent_db.arn
        }
        
        output "rds_instance_port" {
          value       = aws_db_instance.cloudstudent_db.port
        }
        ```
        
    - VPC
        - main.tf
            
            ```bash
            # Define VPC
            resource "aws_vpc" "tf-cs-VPC" {
                cidr_block = "${var.vpc-cidr-block}"
                tags = {
                    Name = "${var.VPC-name}-VPC"
                }
            }
            
            # Define Public Subnet 1a
            resource "aws_subnet" "tf-cs-public-subnet-1a" {
                vpc_id = aws_vpc.tf-cs-VPC.id
                cidr_block = var.public-subnet-1a
                availability_zone = var.az1
                tags = {
                    Name =  "${var.VPC-name}-web-pub-subnet-1a"
                }
            }
            
            # Define Public Subnet 1b
            resource "aws_subnet" "tf-cs-public-subnet-1b" {
                vpc_id = aws_vpc.tf-cs-VPC.id
                cidr_block = var.public-subnet-1b
                availability_zone = var.az2
                tags = {
                    Name =  "${var.VPC-name}-web-pub-subnet-1b"
                }
            }
            
            # Define Private Subnet 2a
            resource "aws_subnet" "tf-cs-private-subnet-2a" {
                vpc_id = aws_vpc.tf-cs-VPC.id
                cidr_block = var.private-subnet-2a
                availability_zone = var.az1
                tags = {
                    Name ="${var.VPC-name}-app-pvt-subnet-2a"
                }
            }
            
            # Define Private Subnet 2b
            resource "aws_subnet" "tf-cs-private-subnet-2b" {
                vpc_id = aws_vpc.tf-cs-VPC.id
                cidr_block = var.private-subnet-2b
                availability_zone = var.az2
                tags = {
                    Name ="${var.VPC-name}-app-pvt-subnet-2b"
                }
            }
            
            # Define Private Subnet 3a
            resource "aws_subnet" "tf-cs-private-subnet-3a" {
                vpc_id = aws_vpc.tf-cs-VPC.id
                cidr_block = var.private-subnet-3a
                availability_zone = var.az1
                tags = {
                    Name ="${var.VPC-name}-db-pvt-subnet-3a"
                }
            }
            
            # Define Private Subnet 3b
            resource "aws_subnet" "tf-cs-private-subnet-3b" {
                vpc_id = aws_vpc.tf-cs-VPC.id
                cidr_block = var.private-subnet-3b
                availability_zone = var.az2
                tags = {
                    Name ="${var.VPC-name}-db-pvt-subnet-3b"
                }
            }
            
            # Define internet gateway
            resource "aws_internet_gateway" "tf-cs-igw" {
                vpc_id = aws_vpc.tf-cs-VPC.id
                tags = {
                    Name = "${var.VPC-name}-igw"
                }
            }
            
            # Allocate the Elastic IP
            resource "aws_eip" "tf-nat-eip" {
              domain = "vpc" 
            }
            
            # Define nat gateway
            resource "aws_nat_gateway" "tf-cloudstudent-ngw" {
              allocation_id = aws_eip.tf-nat-eip.id
              subnet_id     = aws_subnet.tf-cs-public-subnet-1a.id
            
              tags = {
                Name = "${var.VPC-name}-ngw"
              }
            
              depends_on = [aws_internet_gateway.tf-cs-igw]
            }
            
            # Define web public route table
            resource "aws_route_table" "tf-web-public-rt" {
              vpc_id = aws_vpc.tf-cs-VPC.id
            
              route {
                cidr_block = var.all-traffic
                gateway_id = aws_internet_gateway.tf-cs-igw.id
              }
              tags = {
                Name = "${var.VPC-name}-web-pub-route-table"
              }
            }
            
            # Define app private route table
            resource "aws_route_table" "tf-app-pvt-rt" {
              vpc_id = aws_vpc.tf-cs-VPC.id
            
              route {
                cidr_block = var.all-traffic
                nat_gateway_id = aws_nat_gateway.tf-cloudstudent-ngw.id
              }
              tags = {
                Name = "${var.VPC-name}-app-pvt-route-table"
              }
            }
            
            # Define db private route table
            resource "aws_route_table" "tf-db-pvt-rt" {
              vpc_id = aws_vpc.tf-cs-VPC.id
              tags = {
                Name = "${var.VPC-name}-db-pvt-route-table"
              }
            }
            
            resource "aws_route_table_association" "tf-web-public-rt-association-1a" {
              subnet_id      = aws_subnet.tf-cs-public-subnet-1a.id
              route_table_id = aws_route_table.tf-web-public-rt.id
            }
            
            resource "aws_route_table_association" "tf-web-public-rt-association-1b" {
              subnet_id = aws_subnet.tf-cs-public-subnet-1b.id
              route_table_id = aws_route_table.tf-web-public-rt.id
            }
            
            resource "aws_route_table_association" "tf-app-pvt-rt-association-2a" {
              subnet_id = aws_subnet.tf-cs-private-subnet-2a.id
              route_table_id = aws_route_table.tf-app-pvt-rt.id
            }
            
            resource "aws_route_table_association" "tf-app-pvt-rt-association-2b" {
              subnet_id = aws_subnet.tf-cs-private-subnet-2b.id
              route_table_id = aws_route_table.tf-app-pvt-rt.id
            }
            
            resource "aws_route_table_association" "tf-db-pvt-rt-association-3a" {
              subnet_id = aws_subnet.tf-cs-private-subnet-3a.id
              route_table_id = aws_route_table.tf-db-pvt-rt.id
            }
            
            resource "aws_route_table_association" "tf-db-pvt-rt-association-3b" {
              subnet_id = aws_subnet.tf-cs-private-subnet-3b.id
              route_table_id = aws_route_table.tf-db-pvt-rt.id
            }
            
            # Define NACL for public subnets
            resource "aws_network_acl" "tf-web-public-nacl" {
              vpc_id = aws_vpc.tf-cs-VPC.id
              subnet_ids = [ aws_subnet.tf-cs-public-subnet-1a.id, aws_subnet.tf-cs-public-subnet-1b.id]
              tags = {
                Name = "${var.VPC-name}-web-public-nacl"
              }
            
              egress {
                protocol   = "-1"
                rule_no    = 100
                action     = "allow"
                cidr_block = var.all-traffic
                from_port  = 0
                to_port    = 0
              }
            
              ingress {
                protocol   = "tcp"
                rule_no    = 100
                action     = "allow"
                cidr_block = var.all-traffic
                from_port  = 80
                to_port    = 80
              }
            
              ingress {
              protocol   = "tcp"
              rule_no    = 90
              action     = "allow"
              cidr_block = "0.0.0.0/0"
              from_port  = 22
              to_port    = 22
              }
            
            # Inbound: Allow Ephemeral ports for incoming client return traffic
              ingress {
                protocol   = "tcp"
                rule_no    = 110
                action     = "allow"
                cidr_block = var.all-traffic
                from_port  = 1024
                to_port    = 65535
              }
            }
            
            # Define NACL for private subnets
            resource "aws_network_acl" "tf-app-private-nacl" {
              vpc_id = aws_vpc.tf-cs-VPC.id
              subnet_ids = [aws_subnet.tf-cs-private-subnet-2a.id, aws_subnet.tf-cs-private-subnet-2b.id, aws_subnet.tf-cs-private-subnet-3a.id, aws_subnet.tf-cs-private-subnet-3b.id]
              tags = {
                Name = "${var.VPC-name}-app-private-nacl"  
              }
            
            # Inbound: Allow HTTP traffic from Public Subnets only
              ingress {
                protocol   = "tcp"
                rule_no    = 100
                action     = "allow"
                cidr_block = var.vpc-cidr-block # Allows complete internal VPC access
                from_port  = 80
                to_port    = 80
              }
            
              # Inbound: Allow Ephemeral return traffic from internet via NAT
              ingress {
                protocol   = "tcp"
                rule_no    = 110
                action     = "allow"
                cidr_block = var.all-traffic
                from_port  = 1024
                to_port    = 65535
              }
            
              ingress {
              protocol   = "tcp"
              rule_no    = 90
              action     = "allow"
              cidr_block = "10.0.0.0/16" # Or 0.0.0.0/0 depending on your jump-box setup
              from_port  = 22
              to_port    = 22
              }
            
              ingress {
                protocol   = "tcp"
                rule_no    = 120
                action     = "allow"
                cidr_block = var.vpc-cidr-block # Fixed: Allows App tier to hit DB subnets on 3306
                from_port  = 3306
                to_port    = 3306
              }
            
              # Outbound: Allow all outbound traffic (To reach RDS and return data to Web tier)
              egress {
                protocol   = "-1"
                rule_no    = 100
                action     = "allow"
                cidr_block = var.all-traffic
                from_port  = 0
                to_port    = 0
              }
            }
            
            #create subnet groups
            resource "aws_db_subnet_group" "tf-cloudstudent_db_subnet_group" {
              name       = "${var.VPC-name}-db-subnet-group"
              subnet_ids = [ aws_subnet.tf-cs-private-subnet-3a.id, aws_subnet.tf-cs-private-subnet-3b.id]
            }
            ```
            
        - variables.tf
        
        ```bash
        variable "VPC-name" {
            default = "cloudstudent"
        }
        
        variable "vpc-cidr-block" {
            default = "10.0.0.0/16"
        }
        
        variable "public-subnet-1a" {
            default = "10.0.0.0/20"
        }
        
        variable "az" {
            default = "ap-south-1"
        }
        
        variable "az1" {
            default = "ap-south-1a"
        }
        
        variable "az2" {
            default = "ap-south-1b"
        }
        
        variable "public-subnet-1b" {
            default = "10.0.16.0/20"
        }
        
        variable "private-subnet-2a" {
            default = "10.0.128.0/20"
        }
        
        variable "private-subnet-2b" {
            default = "10.0.144.0/20"
        }
        
        variable "private-subnet-3a" {
            default = "10.0.160.0/20"
        }
        
        variable "private-subnet-3b" {
            default = "10.0.176.0/20"
        }
        
        variable "all-traffic" {
            default = "0.0.0.0/0"
        }
        ```
        
        - outputs.tf
        
        ```bash
        output "VPC-ID" {
            value = aws_vpc.tf-cs-VPC.id
        }
        
        output "public_subnet_1a_id" {
            value = aws_subnet.tf-cs-public-subnet-1a.id
        }
        
        output "public_subnet_1b_id" {
            value = aws_subnet.tf-cs-public-subnet-1b.id
        }
        
        output "private_subnet_2a_id" {
            value = aws_subnet.tf-cs-private-subnet-2a.id
        }
        
        output "private_subnet_2b_id" {
            value = aws_subnet.tf-cs-private-subnet-2b.id
        }
        
        output "private_subnet_3a_id" {
            value = aws_subnet.tf-cs-private-subnet-3a.id
        }
        
        output "private_subnet_3b_id" {
            value = aws_subnet.tf-cs-private-subnet-3b.id
        }
        
        output "db_subnet_group_name" {
          value = aws_db_subnet_group.tf-cloudstudent_db_subnet_group.name
        }
        ```
        
- Ansible files
    - web-app-setup.yml
    
    ```bash
    ---
    - name: installation of web server
      hosts: web
      become: true
      tasks: 
        - name: Install nginx
          ansible.builtin.apt:
            name: nginx
            state: present      
        - name: start nginx 
          ansible.builtin.systemd_service:
            name: nginx
            state: started
        - name: add file  to html
          ansible.builtin.copy:
            src: index.html
            dest: /var/www/html/index.html
            mode: '0644'
        - name: Configure Reverse Proxy forwarding routes
          template:
            src: nginx-web.conf.j2
            dest: /etc/nginx/sites-available/default
          notify: Reload Web Nginx
      handlers:
        - name: Reload Web Nginx
          service:
              name: nginx
              state: reloaded
              enabled: true
    ## APP TIER
    - name: installation of app tier
      hosts: app
      become: true
      vars_files:
        - secret_vars.yml
      vars: 
        db_host: "{{ vault_db_host }}"
        db_user: "{{ vault_db_user }}"
        db_pass: "{{ vault_db_pass }}"
        db_name: "{{ vault_db_name }}"
        pkg:
          - nginx
          - php
          - php-fpm
          - php-mysql
          - python3-pymysql
      tasks:
        - name: Installation of nginx & php
          ansible.builtin.apt:
            name: "{{pkg}}"
            state: present
            update_cache: yes
        - name: add file to dest
          ansible.builtin.copy:
            src: submit.php
            dest: /var/www/html/submit.php
            mode: '0644'
        - name: Configure Application local processing sockets
          template:
              src: nginx-app.conf.j2
              dest: /etc/nginx/sites-available/default
          notify: Restart App Services
        - name: Ensure the students table structure exists in RDS
          community.mysql.mysql_query:
            login_host: "{{ db_host }}"
            login_user: "{{ db_user }}"
            login_password: "{{ db_pass }}"
            login_db: "{{ db_name }}"
            query: |
              CREATE TABLE IF NOT EXISTS students (
                  id INT AUTO_INCREMENT PRIMARY KEY,
                  name VARCHAR(100) NOT NULL,
                  email VARCHAR(100) NOT NULL UNIQUE,
                  phone VARCHAR(20) NOT NULL,
                  place VARCHAR(100) NOT NULL,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
              );
      handlers:
        - name: Restart App Services
          service: 
              name: "{{item}}"
              state: restarted
              enabled: true
          loop:
              - nginx
              - php8.5-fpm
          become: yes
    ```
    
    - secret_vars.yml
    
    ```bash
    vault_db_host: "terraform-2026060811213822660000000a.c5qksak4sfmj.ap-south-1.rds.amazonaws.com"
    vault_db_name: "student_db"
    vault_db_user: "admin"
    vault_db_pass: "cloudstudent123"
    ```
    
    - ansible cfg
    
    ```
    [defaults]
    
    inventory = ./inventory.ini
    
    private_key_file = /home/ec2-user/ansible/cloudstudent.pem
    
    host_key_checking = False
    
    display_skipped_hosts = False
    
    become = True
    become_method = sudo
    become_user = root
    ```
    
    - nginx-web.conf.j2
    
    ```
    server {
        listen 80;
        server_name _;
    
        root /var/www/html;
        index index.html;
    
        location / {
            try_files $uri $uri/ =404;
        }
    
        location /submit.php {
            proxy_pass http://{{ hostvars[groups['app'][0]]['ansible_host'] }}:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
    ```
    
    - nginx-app.conf.j2
    
    ```
    server {
        listen 80;
        server_name _;
    
        root /var/www/html;
        index submit.php;
    
        location / {
            try_files $uri $uri/ =404;
        }
    
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php8.5-fpm.sock;
            
            fastcgi_param DB_HOST "{{ db_host }}";
            fastcgi_param DB_NAME "{{ db_name }}";
            fastcgi_param DB_USER "{{ db_user }}";
            fastcgi_param DB_PASS "{{ db_pass }}";
    
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
    ```
    
    - inventory.ini
    
    ```
    [web]
    web_server_1a ansible_host=13.233.190.165 ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/ansible/cloudstudent.pem
    web_server_1b ansible_host=13.233.117.28  ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/ansible/cloudstudent.pem
    
    [web:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=cloudstudent.pem
    
    [app]
    app_server_2a ansible_host=10.0.141.129 ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/ansible/cloudstudent.pem
    app_server_2b ansible_host=10.0.158.98 ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/ansible/cloudstudent.pem
    
    [app:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=cloudstudent.pem
    ```
    
    ### Github Repository link
    
    https://github.com/sakshigit07/-3-Tier-Infrastructure-Deployment-Using-Terraform-Modules.git
    

## PREREQUISITES

Before running this pipeline make sure that following environments matches the criteria.

- **Ansible Instance:** There must be one ansible instance with ansible installed on it to reach out target servers.
- **Terraform CLI:**  Install Terraform CLI on your local machine to deploy.
- **Code:** Ensure your application code is tested and  ready to deploy.
- **IAM Role:** Create an AWS IAM role with administrationaccess for terraform.
- **S3 Bucket:** Create S3 bucket for state lock file. Named as `cloudstudent-terraform-state-bucket`
- **DynamoDB:** Create DynamoDB table named as `cloudstudent-terraform-locks` with a primary partition key named `LockID` to handle state locking.

## STEPS TO DEPLOY

Follow the sequence to build CI/CD and deploy code.

#### 1. Open VS Code & Copy paste all the code as per tree structure.

```bash
Project 3
│   .gitignore
│   form.sql
│   index.html
│   project3.drawio
│   submit.php
│   
├───ansible
│       ansible.cfg
│       nginx-app.conf.j2
│       nginx-web.conf.j2
│       secret_vars.yml
│       web-app-setup.yml
│       
└───terraform
    │   inventory.ini
    │   main.tf
    │   outputs.tf
    │   variables.tf
    │                               
    └───module
        ├───ec2
        │       main.tf
        │       outputs.tf
        │       variables.tf
        │       
        ├───rds
        │       main.tf
        │       outputs.tf
        │       variables.tf
        │       
        └───vpc
                main.tf
                outputs.tf
                variables.tf
```

#### 2. Open git bash and run following commands:

- Initialize Terraform

```bash
terraform init
```

- View blueprint of structure

```bash
terraform plan
```

- To build real infrastructure.

```bash
terrafrom apply --auto-approve
```

- Update `inventory.ini` file in ansible server.
- Execute ansible playbook command:

```bash
ansible playbook -i inventory.ini web-app-setup.yml
```

- Copy the public IP address of your web server and open it in a browser.

## How the system works

The application follows a **3-tier architecture**, where every request passes through three layers in order:

```bash
		Web Tier -> App tier -> Database Tier
```

Each tier have their own responsibility and communicates with each other.

WORKFLOW

```bash
User Browser -> Web server(nginx) -> App server(php-fpm) -> RDS Database(MySQL)
```

1. **Web server (Public Subnet)**
    - The user opens the website in their browser.
    - The request reaches the **Web Server**, which is in the **public subnet**.
    - If the request is for a PHP page (such as `submit.php`), it forwards the request to the **App Server** using **Nginx reverse proxy**.
2. **App server (Private Subnet)** 
    - The **App Server** is in a **private subnet**, so it cannot be accessed directly from the internet.
    - It only accepts requests coming from the Web Server.
    - Nginx on the App Server passes the PHP request to **PHP-FPM**.
    - PHP-FPM executes the PHP code, processes the form data, and prepares the database query.
3. **RDS Database (MySQL)**
    - The processed data is sent to **AWS RDS MySQL**.
    - The RDS database is also in a **private subnet**.
    - It only allows connections on **Port 3306** from the **Application Server's Security Group**.
    - The database stores the student information securely.

### Screenshots of outputs and infrastructure

- Outputs

![alt text](Screenshot(299).png)

- RDS created by Terraform

![alt text](Screenshot(298).png)     

- VPC created by Terraform

![alt text](Screenshot(297).png)

- 5 server : 2 servers of web , 2 servers of app and 1 ansible server

![alt text](Screenshot(296).png)  

Sample app: 

![alt text](Screenshot(295).png)

![alt text](Screenshot(294).png)

---

## Tear down the infrastructure

To avoid unnecessary charges by AWS, simply run the following command :

```bash
terraform destroy --auto-approve
```

This command will terminate the whole infrastructure created by **Terraform** only**.**