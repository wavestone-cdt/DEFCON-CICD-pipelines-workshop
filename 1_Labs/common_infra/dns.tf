# Currently use a pre-registered DNS zone
data "aws_route53_zone" "lab_zone" {
  provider = aws.dns
  name = var.dns_zone_name
}
