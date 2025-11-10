# SNS (Simple Notification Service) Configuration
# This file defines SNS topics and subscriptions for CloudWatch alarm notifications

# SNS Topic for CloudWatch Alarms
# Central topic for receiving notifications from all CloudWatch alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms"

  tags = {
    Name        = "${var.project_name}-sns-alarms"
    Description = "SNS topic for CloudWatch alarm notifications"
  }
}

# SNS Email Subscription
# Email subscription for alarm notifications (requires confirmation)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.email_address
}
