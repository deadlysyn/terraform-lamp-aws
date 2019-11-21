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
  subnet_ids = aws_subnet.private_subnets[*].id
}

resource "aws_db_instance" "rds" {
  vpc_security_group_ids  = [aws_security_group.mysql_ingress.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
  maintenance_window      = "Sat:00:00-Sat:03:00"
  multi_az                = true
  allocated_storage       = 10
  backup_retention_period = 0
  skip_final_snapshot     = true
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = var.db_instance_type
  name                    = "testdb"
  username                = "root"
  password                = var.db_password
  parameter_group_name    = "default.mysql5.7"
}
