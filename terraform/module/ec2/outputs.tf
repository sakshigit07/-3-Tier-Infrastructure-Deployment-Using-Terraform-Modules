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

