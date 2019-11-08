output "web_external_dns" {
  value = "${aws_lb.alb.dns_name}"
}

