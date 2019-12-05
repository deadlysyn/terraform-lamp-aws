output "web_external_dns" {
  value = aws_lb.alb.dns_name
}

output "name_servers" {
  value = aws_route53_zone.public.name_servers
}
