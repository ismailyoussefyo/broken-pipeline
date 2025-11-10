# ECR (Elastic Container Registry) Configuration
# This file defines the container registry for storing application images

# ECR Repository for Application Container Images
# Stores Docker images for the hello-world application
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"

  # Enable image scanning on push for security
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ecr-app"
    Description = "ECR repository for application container images"
  }
}
