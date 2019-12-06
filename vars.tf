variable "env_name" {
  description = "Short descriptive name to help identify resources we create"
  type        = string
}

variable "region" {
  description = "AWS region to target"
  type        = string
}

variable "alt_names" {
  description = "Subject Alternate Names for TLS cert; web_domain will also be included"
  type        = list(string)
}

variable "web_domain" {
  description = "Top-level domain / Route53 Hosted Zone e.g. example.com"
  type        = string
}

variable "web_message" {
  description = "Message displayed on web page"
  type        = string
}

variable "web_port" {
  description = "Private subnet NGINX port"
  type        = string
}

variable "lb_port" {
  description = "Internet-facing ALB port"
  type        = string
}

variable "web_instance_type" {
  type = string
}

variable "web_count_min" {
  description = "Starting point for web auto scaling group"
  type        = string
}

variable "web_count_max" {
  description = "Upper bound for web auto scaling group"
  type        = string
}

variable "db_instance_type" {
  type = string
}

variable "db_password" {
  description = "RDS instance password; sourced from environment"
  type        = string
}

variable "vpc_cidr" {
  description = "RFC1918 CIDR range for VPC"
  type        = string
}

variable "public_cidr" {
  description = "RFC1918 CIDR range for public subnets (subset of vpc_cidr)"
  type        = string
}

variable "private_cidr" {
  description = "RFC1918 CIDR range for private subnets (subset of vpc_cidr)"
  type        = string
}
