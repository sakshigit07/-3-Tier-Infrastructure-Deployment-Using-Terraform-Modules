# Define VPC
resource "aws_vpc" "tf-cs-VPC" {
    cidr_block = "${var.vpc-cidr-block}"
    tags = {
        Name = "${var.VPC-name}-VPC"
    }
}

# Define Public Subnet 1a
resource "aws_subnet" "tf-cs-public-subnet-1a" {
    vpc_id = aws_vpc.tf-cs-VPC.id
    cidr_block = var.public-subnet-1a
    availability_zone = var.az1
    tags = {
        Name =  "${var.VPC-name}-web-pub-subnet-1a"
    }
}

# Define Public Subnet 1b
resource "aws_subnet" "tf-cs-public-subnet-1b" {
    vpc_id = aws_vpc.tf-cs-VPC.id
    cidr_block = var.public-subnet-1b
    availability_zone = var.az2
    tags = {
        Name =  "${var.VPC-name}-web-pub-subnet-1b"
    }
}


# Define Private Subnet 2a
resource "aws_subnet" "tf-cs-private-subnet-2a" {
    vpc_id = aws_vpc.tf-cs-VPC.id
    cidr_block = var.private-subnet-2a
    availability_zone = var.az1
    tags = {
        Name ="${var.VPC-name}-app-pvt-subnet-2a"
    }
}

# Define Private Subnet 2b
resource "aws_subnet" "tf-cs-private-subnet-2b" {
    vpc_id = aws_vpc.tf-cs-VPC.id
    cidr_block = var.private-subnet-2b
    availability_zone = var.az2
    tags = {
        Name ="${var.VPC-name}-app-pvt-subnet-2b"
    }
}

# Define Private Subnet 3a
resource "aws_subnet" "tf-cs-private-subnet-3a" {
    vpc_id = aws_vpc.tf-cs-VPC.id
    cidr_block = var.private-subnet-3a
    availability_zone = var.az1
    tags = {
        Name ="${var.VPC-name}-db-pvt-subnet-3a"
    }
}

# Define Private Subnet 3b
resource "aws_subnet" "tf-cs-private-subnet-3b" {
    vpc_id = aws_vpc.tf-cs-VPC.id
    cidr_block = var.private-subnet-3b
    availability_zone = var.az2
    tags = {
        Name ="${var.VPC-name}-db-pvt-subnet-3b"
    }
}


# Define internet gateway
resource "aws_internet_gateway" "tf-cs-igw" {
    vpc_id = aws_vpc.tf-cs-VPC.id
    tags = {
        Name = "${var.VPC-name}-igw"
    }
}

# Allocate the Elastic IP
resource "aws_eip" "tf-nat-eip" {
  domain = "vpc" 
}

# Define nat gateway
resource "aws_nat_gateway" "tf-cloudstudent-ngw" {
  allocation_id = aws_eip.tf-nat-eip.id
  subnet_id     = aws_subnet.tf-cs-public-subnet-1a.id

  tags = {
    Name = "${var.VPC-name}-ngw"
  }

  depends_on = [aws_internet_gateway.tf-cs-igw]
}

# Define web public route table
resource "aws_route_table" "tf-web-public-rt" {
  vpc_id = aws_vpc.tf-cs-VPC.id

  route {
    cidr_block = var.all-traffic
    gateway_id = aws_internet_gateway.tf-cs-igw.id
  }
  tags = {
    Name = "${var.VPC-name}-web-pub-route-table"
  }
}

# Define app private route table
resource "aws_route_table" "tf-app-pvt-rt" {
  vpc_id = aws_vpc.tf-cs-VPC.id

  route {
    cidr_block = var.all-traffic
    nat_gateway_id = aws_nat_gateway.tf-cloudstudent-ngw.id
  }
  tags = {
    Name = "${var.VPC-name}-app-pvt-route-table"
  }
}

# Define db private route table
resource "aws_route_table" "tf-db-pvt-rt" {
  vpc_id = aws_vpc.tf-cs-VPC.id
  tags = {
    Name = "${var.VPC-name}-db-pvt-route-table"
  }
}

resource "aws_route_table_association" "tf-web-public-rt-association-1a" {
  subnet_id      = aws_subnet.tf-cs-public-subnet-1a.id
  route_table_id = aws_route_table.tf-web-public-rt.id
}

resource "aws_route_table_association" "tf-web-public-rt-association-1b" {
  subnet_id = aws_subnet.tf-cs-public-subnet-1b.id
  route_table_id = aws_route_table.tf-web-public-rt.id
}

resource "aws_route_table_association" "tf-app-pvt-rt-association-2a" {
  subnet_id = aws_subnet.tf-cs-private-subnet-2a.id
  route_table_id = aws_route_table.tf-app-pvt-rt.id
}

resource "aws_route_table_association" "tf-app-pvt-rt-association-2b" {
  subnet_id = aws_subnet.tf-cs-private-subnet-2b.id
  route_table_id = aws_route_table.tf-app-pvt-rt.id
}

resource "aws_route_table_association" "tf-db-pvt-rt-association-3a" {
  subnet_id = aws_subnet.tf-cs-private-subnet-3a.id
  route_table_id = aws_route_table.tf-db-pvt-rt.id
}

resource "aws_route_table_association" "tf-db-pvt-rt-association-3b" {
  subnet_id = aws_subnet.tf-cs-private-subnet-3b.id
  route_table_id = aws_route_table.tf-db-pvt-rt.id
}


# Define NACL for public subnets
resource "aws_network_acl" "tf-web-public-nacl" {
  vpc_id = aws_vpc.tf-cs-VPC.id
  subnet_ids = [ aws_subnet.tf-cs-public-subnet-1a.id, aws_subnet.tf-cs-public-subnet-1b.id]
  tags = {
    Name = "${var.VPC-name}-web-public-nacl"
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.all-traffic
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.all-traffic
    from_port  = 80
    to_port    = 80
  }

  ingress {
  protocol   = "tcp"
  rule_no    = 90
  action     = "allow"
  cidr_block = "0.0.0.0/0"
  from_port  = 22
  to_port    = 22
  }

# Inbound: Allow Ephemeral ports for incoming client return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.all-traffic
    from_port  = 1024
    to_port    = 65535
  }
}

# Define NACL for private subnets
resource "aws_network_acl" "tf-app-private-nacl" {
  vpc_id = aws_vpc.tf-cs-VPC.id
  subnet_ids = [aws_subnet.tf-cs-private-subnet-2a.id, aws_subnet.tf-cs-private-subnet-2b.id, aws_subnet.tf-cs-private-subnet-3a.id, aws_subnet.tf-cs-private-subnet-3b.id]
  tags = {
    Name = "${var.VPC-name}-app-private-nacl"  
  }

# Inbound: Allow HTTP traffic from Public Subnets only
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc-cidr-block # Allows complete internal VPC access
    from_port  = 80
    to_port    = 80
  }

  # Inbound: Allow Ephemeral return traffic from internet via NAT
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.all-traffic
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
  protocol   = "tcp"
  rule_no    = 90
  action     = "allow"
  cidr_block = "10.0.0.0/16" # Or 0.0.0.0/0 depending on your jump-box setup
  from_port  = 22
  to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.vpc-cidr-block # Fixed: Allows App tier to hit DB subnets on 3306
    from_port  = 3306
    to_port    = 3306
  }

  # Outbound: Allow all outbound traffic (To reach RDS and return data to Web tier)
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.all-traffic
    from_port  = 0
    to_port    = 0
  }
}

#create subnet groups
resource "aws_db_subnet_group" "tf-cloudstudent_db_subnet_group" {
  name       = "${var.VPC-name}-db-subnet-group"
  subnet_ids = [ aws_subnet.tf-cs-private-subnet-3a.id, aws_subnet.tf-cs-private-subnet-3b.id]
}