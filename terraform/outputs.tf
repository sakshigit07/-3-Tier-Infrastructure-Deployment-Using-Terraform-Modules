
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