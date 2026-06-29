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
