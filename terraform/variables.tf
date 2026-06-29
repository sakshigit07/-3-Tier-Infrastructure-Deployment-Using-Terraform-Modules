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