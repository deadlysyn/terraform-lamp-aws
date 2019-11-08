variable "env_name" {
  description = "Short descriptive name to help identify resources we create"
  type        = "string"
}

variable "region" {
  type    = "string"
  default = "us-east-2"
}

variable "db_instance_type" {
  type    = "string"
  default = "db.t2.micro"
}

variable "db_password" {
  description = "RDS instance password"
  type        = "string"
}

variable "vpc_cidr" {
  type    = "string"
  default = "10.1.0.0/16"
}

variable "public_cidr" {
  type    = "string"
  default = "10.1.1.0/24"
}

variable "private_cidr" {
  type    = "string"
  default = "10.1.2.0/24"
}

