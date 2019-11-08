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

