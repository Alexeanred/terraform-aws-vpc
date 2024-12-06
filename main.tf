provider "aws" {
  region = var.region
}

# tao vpc
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    "Name" = "udemy"
  }
}
# hello
# locals {
#   private = ["10.0.1.0/24", "10.0.2.0/24"]
#   public  = ["10.0.3.0/24", "10.0.4.0/24"]
#   zone    = ["us-east-1a", "us-east-1b"]
# }

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr[count.index]                   # lấy private[0] và private[1]
  availability_zone = var.availability_zone[count.index % length(var.availability_zone)] # lấy zone[0 % 2 = 0] và zone [1 % 2 = 1]

  tags = {
    "Name" : "private-subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = var.availability_zone[count.index % length(var.public_subnet_cidr)]

  tags = {
    "Name" = "public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "udemy"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "public"
  }
}


resource "aws_route_table_association" "public_association" {
  for_each       = { for k, v in aws_subnet.public_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

#  0 = { id = "subnet-123", name = "public-subnet-0" },
# 1 = { id = "subnet-456", name = "public-subnet-1" }

# NAT gw
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.igw]
  domain     = "vpc"
}

resource "aws_nat_gateway" "public" {
  depends_on = [aws_internet_gateway.igw]

  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "Public NAT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public.id
  }

  tags = {
    "Name" = "private"
  }
}

resource "aws_route_table_association" "public_private" {
  for_each       = { for k, v in aws_subnet.private_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
