provider "aws" {
  region = var.region
}

data "aws_availability_zones" "all" {}

######################################################################
# Network configuration
######################################################################

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    "Name" = "${var.env_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.env_name}-igw"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "${var.env_name}-public-route"
  }
}

resource "aws_route_table_association" "public_rta" {
  count          = length(data.aws_availability_zones.all.names)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_route.id
}

resource "aws_subnet" "public_subnets" {
  count                   = length(data.aws_availability_zones.all.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.public_cidr, 2, count.index)
  availability_zone       = element(data.aws_availability_zones.all.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.env_name}-public-subnet${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(data.aws_availability_zones.all.names)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.private_cidr, 2, count.index)
  availability_zone = element(data.aws_availability_zones.all.names, count.index)

  tags = {
    "Name" = "${var.env_name}-private-subnet${count.index}"
  }
}

