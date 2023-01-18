#---------------------------------------------------------------------
# My Terraform Module "AWS-Network"
# 
# Provision:
#  - VPC
#  - Internet Gateway
#  - XX Public Subnets
#  - XX Private Subnets
#  - XX NAT Gateways in Public Subnets to give access to Internet from Private Subnets
#
# Made by 6nsh
#
#---------------------------------------------------------------------

data "aws_availability_zones" "available" {}


resource "aws_vpc" "main-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name  = "My Main ${var.env} VPC"
    Owner = "6nsh"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name  = "My Main ${var.env} Gateway"
    Owner = "6nsh"
  }
}


#----------Private Subnets and Routes-------------------

resource "aws_subnet" "public-subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name  = "${var.env}-public-${count.index + 1}"
    Owner = "6nsh"
  }
}


resource "aws_route_table" "public-subnets" {
  vpc_id = aws_vpc.main-vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.env}-public-route"
  }
}


resource "aws_route_table_association" "public-routes" {
  count          = length(aws_subnet.public-subnets[*].id)
  route_table_id = aws_route_table.public-subnets.id
  subnet_id      = element(aws_subnet.public-subnets[*].id, count.index)
}


#--------------NAT GW and EIP------------------------------

resource "aws_eip" "nat-eip" {
  count = length(var.private_subnet_cidrs)
  vpc   = true
  
  tags = {
    Name = "${var.env}-nat-eip-gw-${count.index + 1}"
  }
}


resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat-eip[count.index].id
  subnet_id     = element(aws_subnet.public-subnets[*].id, count.index)
  
  tags = {
    Name = "${var.env}-nat-gw-${count.index + 1}"
  }
}


#----------------Private Subnets and Routes--------------------------------

resource "aws_subnet" "private-subnets" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = element(var.private_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name  = "${var.env}-private-${count.index + 1}"
    Owner = "6nsh"
  }
}


resource "aws_route_table" "private-subnets" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main-vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }
  
  tags = {
    Name = "${var.env}-route-private-${count.index + 1}"
  }
}


resource "aws_route_table_association" "private-routes" {
  count          = length(aws_subnet.private-subnets[*].id)
  route_table_id = aws_route_table.private-subnets[count.index].id
  subnet_id      = element(aws_subnet.private-subnets[*].id, count.index)
}
