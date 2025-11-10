# Terraform Standards and File Structure

## File Splitting Standard

Resources are organized by type and layer for better maintainability:

- **main.tf**: Provider configuration and entry point
- **data.tf**: Data sources (availability zones, account info, region)
- **variables.tf**: Input variables with object types and defaults
- **outputs.tf**: Output values
- **versions.tf**: Terraform and provider version constraints
- **vpc.tf**: VPC, subnets, peering, and Network ACLs
- **security.tf**: WAF rules and geo-restrictions
- **s3.tf**: S3 buckets for logging (ALB logs, ECS logs, pipeline logs)
- **iam.tf**: IAM roles and policies
- **ecr.tf**: ECR repositories
- **route53.tf**: Route53 hosted zones, records, and certificates
- **sns.tf**: SNS topics and subscriptions
- **monitoring.tf**: CloudWatch alarms
- **ecs.tf**: ECS cluster module calls

## Commenting Standards

Every Terraform resource includes:
- A brief description of its purpose
- Comments explaining configuration choices
- Location comments for related resources (e.g., "ALB for Jenkins in public subnet")

Example:
```hcl
# Application Load Balancer for Jenkins
# Public-facing ALB in Jenkins VPC public subnets, restricted to Portugal via WAF
resource "aws_lb" "jenkins" {
  # ... configuration
}
```

## Flaw Documentation

All deliberate flaws are clearly marked with:
- **FLAW #X**: Numbered flaw identifier
- **Description**: What the flaw is
- **Impact**: What the flaw affects
- **Fix**: How to correct it

Example:
```hcl
# FLAW #1: Security group allows traffic from ALB but uses wrong port range
# The ingress rule should only allow the container_port (e.g., 80), but it allows a wider range (80-180)
# Impact: Security concern - allows potential access to ports beyond the intended container port
# Fix: Change to_port = var.container_port + 100 to to_port = var.container_port
```

## Variable Standards

Variables use object types with optional defaults:

```hcl
variable "tags" {
  description = "Tags to apply to all resources"
  type = object({
    environment = optional(string, "develop")
    product     = optional(string, "cloud")
    service     = optional(string, "pipeline")
    managed_by  = optional(string, "terraform")
    project     = optional(string, "BrokenPipeline")
  })
  default = {
    environment = "develop"
    product     = "cloud"
    service     = "pipeline"
    managed_by  = "terraform"
    project     = "BrokenPipeline"
  }
}
```

## Provider Configuration

The AWS provider uses `default_tags` to apply consistent tagging:

```hcl
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
```

## Deliberate Flaws

This infrastructure contains exactly three subtle flaws:

1. **Terraform Flaw** (`terraform/modules/ecs-cluster/main.tf`):
   - Security group port range issue
   - Allows wider port range than necessary

2. **Pipeline Flaw** (`jenkins/Jenkinsfile`):
   - Missing error handling in Build stage
   - Pipeline continues even if Docker build fails

3. **Script Flaw** (`scripts/verify_health.sh`):
   - Incomplete health verification
   - Only checks if container is running, not if HTTP endpoint responds

All flaws are clearly documented with comments explaining the issue, impact, and fix.

