# Create all necessary domains (1 for gitlab, 1 for jenkins & 1 for kali)
resource "aws_route53_record" "kali" {
  provider = aws.dns
  zone_id = local.dns_zone_id
  name    = "${ lower(terraform.workspace) }-kali"
  type    = "A"
  ttl     = var.dns_record_ttl
  records = [aws_instance.jump_kali.public_ip]
}
resource "aws_route53_record" "gitlab" {
  provider = aws.dns
  zone_id = local.dns_zone_id
  name    = "${ lower(terraform.workspace) }-gitlab"
  type    = "A"
  ttl     = var.dns_record_ttl
  records = [aws_instance.gitlab.public_ip]
}
resource "aws_route53_record" "jenkins" {
  provider = aws.dns
  zone_id = local.dns_zone_id
  name    = "${ lower(terraform.workspace) }-jenkins"
  type    = "A"
  ttl     = var.dns_record_ttl
  records = [aws_instance.jenkins.public_ip]
}
