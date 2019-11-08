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

######################################################################
# RDS configuration
######################################################################

resource "aws_security_group" "mysql_ingress" {
  name   = "${var.env_name}-myql-ingress-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = "${aws_subnet.private_subnets.*.id}"
}

resource "aws_db_instance" "rds" {
  vpc_security_group_ids  = [aws_security_group.mysql_ingress.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
  maintenance_window      = "Sat:00:00-Sat:03:00"
  multi_az                = true
  allocated_storage       = 10
  backup_retention_period = 0
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = var.db_instance_type
  name                    = "testdb"
  username                = "root"
  password                = var.db_password
  parameter_group_name    = "default.mysql5.7"
}

######################################################################
# Web configuration
######################################################################

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = ["099720109477"]
}

resource "aws_security_group" "http_ingress_instance" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = var.web_port
    to_port     = var.web_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.env_name}-http-ingress-instance-sg"
  }
}

resource "aws_launch_configuration" "lc" {
  # avoid name so ASG can be updated without conflicts
  name_prefix     = "${var.env_name}-"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = var.web_instance_type
  security_groups = [aws_security_group.http_ingress_instance.id]
  user_data = templatefile("userdata.sh", {
    web_port    = var.web_port,
    web_message = var.web_message,
    db_endpoint = aws_db_instance.rds.endpoint,
    db_name     = aws_db_instance.rds.name,
    db_username = aws_db_instance.rds.username,
    db_status   = aws_db_instance.rds.status
  })
}

resource "aws_autoscaling_group" "asg" {
  name     = "${var.env_name}-web-asg"
  min_size = var.web_count_min
  max_size = var.web_count_max

  launch_configuration = aws_launch_configuration.lc.name
  vpc_zone_identifier  = "${aws_subnet.private_subnets.*.id}"

  target_group_arns     = [aws_lb_target_group.tg.arn]
  health_check_type     = "ELB"
  wait_for_elb_capacity = 1

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.env_name}-instance-${uuid()}"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "http_ingress_lb" {
  name   = "${var.env_name}-http-ingress-lb-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.http_ingress_lb.id]
  subnets            = "${aws_subnet.public_subnets.*.id}"

  tags = {
    "Name" = "${var.env_name}-web-lb"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tg" {
  vpc_id   = aws_vpc.vpc.id
  port     = var.web_port
  protocol = "HTTP"

  health_check {
    path    = "/"
    port    = var.web_port
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.env_name}-web-lb-tg"
  }
}

