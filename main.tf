terraform {
  required_version = ">= 0.12.0"

  required_providers {
    aws = "~> 2.35"
  }
}

provider "aws" {
  region = var.region
}


locals {
  # When we have 2-4 AZs in a region divide the public and private
  # CIDR ranges into 4 subnets (add 2 bits to netmask). In larger
  # regions with >4 AZs, divide into 8 subnets (add 3 bits).
  newbits = length(data.aws_availability_zones.available.names) > 4 ? 3 : 2
  fqdns   = concat([var.web_domain], var.alt_names)
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
  # Avoid static name so resource can be updated.
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
  # Avoid static name so resource can be updated.
  name_prefix               = "${var.env_name}-asg-"
  min_size                  = var.web_count_min
  max_size                  = var.web_count_max
  desired_capacity          = var.web_count_min
  default_cooldown          = 60
  health_check_grace_period = 120

  launch_configuration = aws_launch_configuration.lc.name
  vpc_zone_identifier  = aws_subnet.private_subnets[*].id

  target_group_arns     = [aws_lb_target_group.tg.arn]
  health_check_type     = "ELB"
  wait_for_elb_capacity = 1

  # Ensure we have a validated cert before spinning up
  # ASG which relies on ALB/Listener health.
  depends_on = [aws_acm_certificate_validation.cert]

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
    from_port   = var.lb_port
    to_port     = var.lb_port
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

resource "aws_acm_certificate" "cert" {
  domain_name               = var.web_domain
  subject_alternative_names = var.alt_names
  validation_method         = "DNS"

  tags = {
    "Name" = "${var.env_name}-acm-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = aws_route53_record.cert_validation[*].fqdn
}

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
  port              = var.lb_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

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

