output "alb_external_dns" {
  value = aws_lb.alb.dns_name
}

output "acm_cert_arn" {
  value = aws_acm_certificate.cert.arn
}

output "name_servers" {
  value = aws_route53_zone.public.name_servers
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "rds_db_name" {
  value = aws_db_instance.rds.name
}

output "rds_username" {
  value = aws_db_instance.rds.username
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnets" {
  value = aws_subnet.private_subnets[*].id
}

output "elastic_ips" {
  value = aws_eip.nat_eip[*].id
}

output "ami_id" {
  value = data.aws_ami.ubuntu.id
}
