variable "env_name" {
  description = "Short descriptive name to help identify resources we create"
  type        = "string"
}

variable "web_message" {
  description = "Message displayed on web page"
  type        = "string"
  default     = "Hello World!"
}

variable "web_port" {
  type    = "string"
  default = "80"
}

variable "web_instance_type" {
  type    = "string"
  default = "t2.nano"
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

