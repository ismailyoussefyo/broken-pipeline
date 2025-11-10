output "app_alb_dns" {
  description = "Application ALB DNS name"
  value       = module.app_ecs.alb_dns_name
}

output "app_route53_record" {
  description = "Application Route53 record"
  value       = module.app_ecs.route53_record_name
}

output "jenkins_alb_dns" {
  description = "Jenkins ALB DNS name"
  value       = module.jenkins_ecs.alb_dns_name
}

output "jenkins_route53_record" {
  description = "Jenkins Route53 record"
  value       = module.jenkins_ecs.route53_record_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = length(aws_route53_zone.main) > 0 ? aws_route53_zone.main[0].zone_id : ""
}
