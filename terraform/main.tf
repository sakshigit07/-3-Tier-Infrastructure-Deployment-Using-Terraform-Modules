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