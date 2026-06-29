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