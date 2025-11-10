# Route53 DNS Configuration
# This file defines DNS hosted zones, records, and health checks
# Note: Route53 and ACM are optional - if domain_name is empty, ALBs can be accessed via DNS names directly

# Route53 Hosted Zone (optional - only created if domain_name is provided)
# Public hosted zone for the domain
resource "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "${var.project_name}-route53-zone"
    Description = "Route53 hosted zone for application and Jenkins"
  }
}

# ACM Certificate for HTTPS (optional - only created if domain_name is provided)
# SSL/TLS certificate for ALB HTTPS listeners
# Note: Requires DNS validation via Route53
resource "aws_acm_certificate" "main" {
  count           = var.domain_name != "" ? 1 : 0
  domain_name     = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-certificate"
    Description = "ACM certificate for ALB HTTPS"
  }
}

# Local value for certificate ARN (empty string if no domain)
locals {
  certificate_arn = var.domain_name != "" ? aws_acm_certificate.main[0].arn : ""
  route53_zone_id = var.domain_name != "" ? aws_route53_zone.main[0].zone_id : ""
}
