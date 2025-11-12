# Main Terraform Configuration
# This file contains the provider configuration and serves as the entry point
# File splitting standard: Resources are organized by type/layer:
#   - data.tf: Data sources
#   - vpc.tf: VPC, subnets, peering, Network ACLs
#   - security.tf: WAF, security groups (in module)
#   - s3.tf: S3 buckets for logging
#   - iam.tf: IAM roles and policies
#   - ecr.tf: ECR repositories
#   - route53.tf: Route53 hosted zones and records
#   - sns.tf: SNS topics and subscriptions
#   - monitoring.tf: CloudWatch alarms
#   - ecs.tf: ECS cluster module calls

terraform {
  required_version = ">= 1.0"
}

# AWS Provider Configuration
# Configured with default_tags to apply consistent tagging across all resources
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.tags.environment
      Product     = var.tags.product
      Service     = var.tags.service
      ManagedBy   = var.tags.managed_by
      Project     = var.tags.project
    }
  }
}
