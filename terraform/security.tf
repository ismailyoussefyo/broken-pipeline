# Security Configuration
# This file defines WAF rules, security groups, and geo-restrictions

# WAF Web ACL for Jenkins ALB Geo-Restriction
# Enforces access restriction to Portugal and Egypt using country-based geo-matching
resource "aws_wafv2_web_acl" "jenkins_geo_restriction" {
  name        = "${var.project_name}-jenkins-waf"
  description = "WAF for Jenkins ALB - Geo-restriction to Portugal and Egypt"
  scope       = "REGIONAL"

  # Default action: block all traffic
  default_action {
    block {}
  }

  # Rule: Allow traffic from Portugal and Egypt
  rule {
    name     = "AllowPortugalAndEgypt"
    priority = 1

    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = ["PT", "EG"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-jenkins-waf-geo-allow"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-jenkins-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-jenkins-waf"
  }
}

# WAF Web ACL Association for Jenkins ALB
# Associates the WAF Web ACL with the Jenkins ALB
resource "aws_wafv2_web_acl_association" "jenkins_alb" {
  resource_arn = module.jenkins_ecs.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.jenkins_geo_restriction.arn
}



