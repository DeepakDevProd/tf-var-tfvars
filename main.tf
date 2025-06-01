terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region_name
}


resource "aws_vpc" "tf-vpc" {
  cidr_block           = var.vpc-cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_tag
  }
}

resource "aws_subnet" "tf-pub_subnet-1" {
  vpc_id                  = aws_vpc.tf-vpc.id
  cidr_block              = var.subnet1-cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.subnet1-az # London AZ A

  tags = {
    Name = var.subnet1_tag
  }
}

resource "aws_subnet" "tf-pub_subnet-2" {
  vpc_id                  = aws_vpc.tf-vpc.id
  cidr_block              = var.subnet2-cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.subnet2-az # London AZ A

  tags = {
    Name = var.subnet2_tag
  }
}

resource "aws_internet_gateway" "tf-igw" {
  vpc_id = aws_vpc.tf-vpc.id
  tags = {
    Name = var.igw_tag
  }
}


resource "aws_route_table" "tf-pub-rtable" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = var.rt_cidr_block
    gateway_id = aws_internet_gateway.tf-igw.id
  }

  tags = {
    Name = var.rt_tag
  }
}


resource "aws_route_table_association" "pub-rta-ass-1" {
  subnet_id      = aws_subnet.tf-pub_subnet-1.id
  route_table_id = aws_route_table.tf-pub-rtable.id
}

resource "aws_route_table_association" "pub-rta-ass-2" {
  subnet_id      = aws_subnet.tf-pub_subnet-2.id
  route_table_id = aws_route_table.tf-pub-rtable.id
}

resource "aws_security_group" "tf-sg" {
  name   = "tf-sg"
  vpc_id = aws_vpc.tf-vpc.id

  # Ingress rules
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule (allow all)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-sg"
  }
}

resource "aws_instance" "tf-ec2" {
  ami                    = "ami-0a94c8e4ca2674d5a"
  availability_zone      = var.ec2_az
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.tf-pub_subnet-1.id
  vpc_security_group_ids = [aws_security_group.tf-sg.id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install nginx -y
              systemctl enable nginx
              systemctl start nginx
              echo "<h1>Hello from Ubuntu + Nginx!</h1>" > /var/www/html/index.html
              EOF


  tags = {
    Name = var.ec2_tag
  }
  lifecycle {
    # prevent_destroy = true
    create_before_destroy = true
  }
}
