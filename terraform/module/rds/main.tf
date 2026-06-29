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