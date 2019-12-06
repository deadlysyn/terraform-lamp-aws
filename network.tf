# Get list of all available AZs in region.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

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

# Note: You could route all traffic through a single NAT gateway, but
# if a single AZ goes down all outbound connecitivity would be lost.
# Consider the cost/risk benefit. This consumes more EIPs (you may
# need to request more), but aside from better HA it also addresses
# NAT scaling factors (bandwidth, connections).

resource "aws_nat_gateway" "ngw" {
  count         = length(data.aws_availability_zones.available.names)
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)
  allocation_id = element(aws_eip.nat_eip[*].id, count.index)
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    "Name" = "${var.env_name}-ngw-${count.index}"
  }
}

resource "aws_eip" "nat_eip" {
  count      = length(data.aws_availability_zones.available.names)
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    "Name" = "${var.env_name}-nat-eip-${count.index}"
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

resource "aws_route_table" "private_route" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ngw[*].id, count.index)
  }

  tags = {
    "Name" = "${var.env_name}-private-route-${count.index}"
  }
}

resource "aws_route_table_association" "public_rta" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private_rta" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = element(aws_route_table.private_route[*].id, count.index)
}

# Note: cidrsubnet will automatically carve smaller subnets out of the
# configured CIDR ranges to satisfy HA and RDS subnet group
# requirements. However, since all regions do not have a consistent
# number of AZs, the size of the auto-generated subnets will vary
# depending on the target region. Be sure to think about scaling
# requirements when selecting CIDR ranges.

resource "aws_subnet" "public_subnets" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.public_cidr, local.newbits, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.env_name}-public-subnet${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.private_cidr, local.newbits, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    "Name" = "${var.env_name}-private-subnet${count.index}"
  }
}
