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
