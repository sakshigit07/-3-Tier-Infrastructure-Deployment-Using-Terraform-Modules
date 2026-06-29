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