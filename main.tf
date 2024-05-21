resource "random_string" "suffix" {
  length  = 8
  upper   = false
  lower   = true
  numeric  = false
  special = false
}

resource "aws_vpc" "ase-eks-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ase-eks-${random_string.suffix.result}"
  }
}


resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.ase-eks-vpc.id
  tags = {
    Name = "ase-eks-Gateway-${random_string.suffix.result}"
  }
}
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.ase-eks-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
  tags = {
    Name = "Public Subnet Route"
  }
}

resource "aws_subnet" "public-subnet1" {
  cidr_block              = var.public_subnet_cidr1
  vpc_id                  = aws_vpc.ase-eks-vpc.id
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ase-eks-Public-Subnet1-${random_string.suffix.result}"
  }
}

resource "aws_subnet" "public-subnet2" {
  cidr_block              = var.public_subnet_cidr2
  vpc_id                  = aws_vpc.ase-eks-vpc.id
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "ase-eks-Public-Subnet2-${random_string.suffix.result}"
  }
}

resource "aws_route_table_association" "public-subnet1" {
  route_table_id = aws_route_table.public-route.id
  subnet_id      = aws_subnet.public-subnet1.id
}

resource "aws_route_table_association" "public-subnet2" {
  route_table_id = aws_route_table.public-route.id
  subnet_id      = aws_subnet.public-subnet2.id
}
