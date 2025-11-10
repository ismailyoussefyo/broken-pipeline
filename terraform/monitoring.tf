# CloudWatch Monitoring and Alarms
# This file defines CloudWatch alarms for application health and cost monitoring

# CloudWatch Alarm for Application ALB - HTTP 5xx Errors
# Monitors 5xx server errors from the application load balancer
resource "aws_cloudwatch_metric_alarm" "app_5xx_errors" {
  alarm_name          = "${var.project_name}-app-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This metric monitors application ALB 5xx errors"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = module.app_ecs.alb_arn_suffix
  }

  tags = {
    Name = "${var.project_name}-app-5xx-alarm"
  }
}

# CloudWatch Alarm for Jenkins ALB - HTTP 5xx Errors
# Monitors 5xx server errors from the Jenkins load balancer
resource "aws_cloudwatch_metric_alarm" "jenkins_5xx_errors" {
  alarm_name          = "${var.project_name}-jenkins-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This metric monitors Jenkins ALB 5xx errors"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    LoadBalancer = module.jenkins_ecs.alb_arn_suffix
  }

  tags = {
    Name = "${var.project_name}-jenkins-5xx-alarm"
  }
}

# CloudWatch Alarm for Application Route53 Health Check
# Monitors Route53 health check status for the application
resource "aws_cloudwatch_metric_alarm" "app_health_check" {
  alarm_name          = "${var.project_name}-app-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "This metric monitors application Route53 health check"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    HealthCheckId = module.app_ecs.health_check_id != "" ? module.app_ecs.health_check_id : "dummy"
  }

  count = module.app_ecs.health_check_id != "" ? 1 : 0

  tags = {
    Name = "${var.project_name}-app-health-check-alarm"
  }
}

# CloudWatch Alarm for Jenkins Route53 Health Check
# Monitors Route53 health check status for Jenkins
resource "aws_cloudwatch_metric_alarm" "jenkins_health_check" {
  alarm_name          = "${var.project_name}-jenkins-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "This metric monitors Jenkins Route53 health check"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    HealthCheckId = module.jenkins_ecs.health_check_id != "" ? module.jenkins_ecs.health_check_id : "dummy"
  }

  count = module.jenkins_ecs.health_check_id != "" ? 1 : 0

  tags = {
    Name = "${var.project_name}-jenkins-health-check-alarm"
  }
}

# CloudWatch Cost Alarm - Daily costs > $1
# Monitors estimated daily AWS charges and alerts when exceeding $1
# Note: Requires billing metrics to be enabled in AWS account
resource "aws_cloudwatch_metric_alarm" "daily_cost" {
  alarm_name          = "${var.project_name}-daily-cost-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400  # 24 hours in seconds
  statistic           = "Maximum"
  threshold           = 1.0
  alarm_description   = "This metric monitors estimated daily AWS charges exceeding $1"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Name = "${var.project_name}-daily-cost-alarm"
  }
}
