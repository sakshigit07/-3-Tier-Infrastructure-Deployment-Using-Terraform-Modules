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
