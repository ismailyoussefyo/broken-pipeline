variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_count" {
  description = "Number of containers to run"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "CPU units for the task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for the task in MiB"
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "is_jenkins" {
  description = "Whether this is a Jenkins deployment (affects security group rules)"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS (optional - leave empty for HTTP only)"
  type        = string
  default     = ""
}

variable "s3_logging_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (optional - leave empty to skip Route53 records)"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "Route53 record name (optional - only used if route53_zone_id is provided)"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/"
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EC2 instances"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

