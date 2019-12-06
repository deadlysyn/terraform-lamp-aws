# Be careful here! You likely want to manage networks, DNS, etc. in
# separate modules (and state!). The Delegation Set name servers
# get plugged into your registrar, so you typically don't want them
# to regularly change. If you apply/destory/apply, you will get a new
# set of name servers and need to update your registrar. A simple
# "prevent_destroy = true" won't help as/of writing due to this issue:
# https://github.com/hashicorp/terraform/issues/3874

resource "aws_route53_delegation_set" "main" {
  reference_name = var.env_name
}

resource "aws_route53_zone" "public" {
  name              = var.web_domain
  delegation_set_id = aws_route53_delegation_set.main.id

  tags = {
    "Name" = "${var.env_name}-route53-hosted-zone"
  }
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.public.zone_id
  name    = var.web_domain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "www.${var.web_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count   = length(concat([var.web_domain], var.alt_names))
  name    = element(aws_acm_certificate.cert.domain_validation_options[*].resource_record_name, count.index)
  type    = element(aws_acm_certificate.cert.domain_validation_options[*].resource_record_type, count.index)
  records = [element(aws_acm_certificate.cert.domain_validation_options[*].resource_record_value, count.index)]
  ttl     = 60
  zone_id = aws_route53_zone.public.zone_id
}
