# S3 Buckets for Logging
# This file defines S3 buckets for ALB access logs, ECS container logs, and pipeline logs

# S3 Bucket for ALB Access Logs
# Stores access logs from both Application and Jenkins ALBs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-alb-logs"
    Description = "ALB access logs bucket"
  }
}

# S3 Bucket Versioning - Disabled for cost optimization
resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3 Bucket Lifecycle Configuration
# Automatically deletes logs older than 30 days to minimize costs
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# S3 Bucket Server-Side Encryption
# Encrypts logs at rest using AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
# Prevents public access to logs
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for ALB Log Writes
# Allows ALB service to write logs to the bucket
# Using ELB service account for eu-central-1: 054676820928
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBLogDelivery"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::054676820928:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

# S3 Bucket for ECS Container Logs and Pipeline Logs
# Centralized logging bucket for ECS container logs and Jenkins pipeline logs
resource "aws_s3_bucket" "application_logs" {
  bucket = "${var.project_name}-app-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-app-logs"
    Description = "ECS container logs and pipeline logs bucket"
  }
}

# S3 Bucket Versioning - Disabled for cost optimization
resource "aws_s3_bucket_versioning" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3 Bucket Lifecycle Configuration
# Automatically deletes logs older than 30 days to minimize costs
resource "aws_s3_bucket_lifecycle_configuration" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# S3 Bucket Server-Side Encryption
# Encrypts logs at rest using AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
# Prevents public access to logs
resource "aws_s3_bucket_public_access_block" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for Log Writes
# Allows ECS tasks, EC2 instances, and Jenkins to write logs
resource "aws_s3_bucket_policy" "application_logs" {
  bucket = aws_s3_bucket.application_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTaskLogWrites"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.ecs_task.arn,
            aws_iam_role.ec2_instance.arn
          ]
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.application_logs.arn}/*"
      },
      {
        Sid    = "AllowECSTaskLogList"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.ecs_task.arn,
            aws_iam_role.ec2_instance.arn
          ]
        }
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.application_logs.arn
      }
    ]
  })
}



