terraform {
  required_version = ">= 0.12.0"

  required_providers {
    aws = "~> 2.35"
  }
}

provider "aws" {
  region = var.region
}

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
  # avoid static name so resource can be updated
  name_prefix     = "${var.env_name}-lc-"
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
  # avoid static name so resource can be updated
  name_prefix = "${var.env_name}-asg-"
  min_size    = var.web_count_min
  max_size    = var.web_count_max

  launch_configuration = aws_launch_configuration.lc.name
  vpc_zone_identifier  = aws_subnet.private_subnets[*].id

  target_group_arns     = [aws_lb_target_group.tg.arn]
  health_check_type     = "ELB"
  wait_for_elb_capacity = 1

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.env_name}-instance"
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

# TODO: Delegate subdomain + ACM config
#
# resource "aws_iam_server_certificate" "test_cert" {
#   name_prefix      = "example-cert"
#   certificate_body = "${file("certs/cert.pem")}"
#   private_key      = "${file("certs/key.pem")}"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

resource "aws_lb" "alb" {
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.http_ingress_lb.id]
  subnets            = aws_subnet.public_subnets[*].id

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

