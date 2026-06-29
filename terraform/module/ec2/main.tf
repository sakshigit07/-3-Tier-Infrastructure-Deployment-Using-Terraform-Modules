# Create sg for web tier
resource "aws_security_group" "tf-web-security-group" {
    name        = "allow http,https,ssh traffic"
  description = "Allow HTTP,SSH,HTTPS traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.VPC-name}-web-security-group"
  }
}  

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4-web" {
  security_group_id = aws_security_group.tf-web-security-group.id
  cidr_ipv4         = "${var.all-traffic}"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4-web" {
  security_group_id = aws_security_group.tf-web-security-group.id
  cidr_ipv4         = "${var.all-traffic}"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-web" {
  security_group_id = aws_security_group.tf-web-security-group.id
  cidr_ipv4         = "${var.all-traffic}"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# Create sg for app tier
resource "aws_security_group" "tf-app-security-group" {
    name        = "allow http traffic from web tier"
  description = "Allow HTTP traffic from web tier only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.VPC-name}-app-security-group"
  }
}
 
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4-app" {
  security_group_id = aws_security_group.tf-app-security-group.id
  referenced_security_group_id = aws_security_group.tf-web-security-group.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4-app" {
  security_group_id = aws_security_group.tf-app-security-group.id
  referenced_security_group_id = aws_security_group.tf-web-security-group.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-app" {
  security_group_id = aws_security_group.tf-app-security-group.id
  cidr_ipv4         = "${var.all-traffic}"
  ip_protocol       = "-1" # semantically equivalent to all ports
}




# Create sg for db tier
resource "aws_security_group" "tf-db-security-group" {
    name        = "allow mysql traffic from app tier"
  description = "Allow mysql traffic from app tier only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.VPC-name}-db-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_mysql_ipv4-db" {
  security_group_id = aws_security_group.tf-db-security-group.id
  referenced_security_group_id = aws_security_group.tf-app-security-group.id
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4-db" {
  security_group_id = aws_security_group.tf-db-security-group.id
  cidr_ipv4         = "${var.all-traffic}"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# Create EC2
## creating web server
resource "aws_instance" "tf-web-public-1a" {
  tags = {
    Name = "${var.VPC-name}-web-1a"
  }
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = [aws_security_group.tf-web-security-group.id]
  key_name = "${var.key_name}"
  subnet_id = var.public_subnet_1a_id
  associate_public_ip_address = true
}

resource "aws_instance" "tf-web-public-1b"{
    tags = {
    Name = "${var.VPC-name}-web-1b"
  }
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = [aws_security_group.tf-web-security-group.id]
  key_name = "${var.key_name}"
  subnet_id = var.public_subnet_1b_id
  associate_public_ip_address = true
}



## create app server
resource "aws_instance" "tf-app-private-2a"{
  tags = {
    Name = "${var.VPC-name}-app-2a"
  }
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = [aws_security_group.tf-app-security-group.id]
  key_name = "${var.key_name}"
  subnet_id = var.private_subnet_2a_id
  associate_public_ip_address = false
}


resource "aws_instance" "tf-app-private-2b"{
    tags = {
    Name = "${var.VPC-name}-app-2b"
  }
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = [aws_security_group.tf-app-security-group.id]
  key_name = "${var.key_name}"
  subnet_id = var.private_subnet_2b_id
  associate_public_ip_address = false
}