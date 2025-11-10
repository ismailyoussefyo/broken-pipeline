variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "broken-pipeline"
}

variable "domain_name" {
  description = "Domain name for Route53 hosted zone (optional - leave empty to use ALB DNS names directly)"
  type        = string
  default     = ""
}

variable "email_address" {
  description = "Email address for SNS notifications"
  type        = string
}

variable "jenkins_allowed_country" {
  description = "Country code for Jenkins ALB restriction (e.g., PT for Portugal)"
  type        = string
  default     = "PT"
}

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
