# EFS File System for Jenkins Persistent Storage
# This file configures Amazon EFS to persist Jenkins data (/var/jenkins_home)
# across container restarts and ECS task redeployments

# EFS File System for Jenkins
resource "aws_efs_file_system" "jenkins" {
  creation_token = "${var.project_name}-jenkins-efs"
  encrypted      = true

  # Lifecycle policy: Move files not accessed for 30 days to Infrequent Access storage class (cost optimization)
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  # Enable automatic backups
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-jenkins-efs"
    Description = "Persistent storage for Jenkins configuration and build history"
  })
}

# EFS Mount Targets (one per private subnet in Jenkins VPC)
# These provide network access points for ECS tasks to mount the EFS file system
resource "aws_efs_mount_target" "jenkins" {
  for_each = toset(module.jenkins_vpc.private_subnets)

  file_system_id  = aws_efs_file_system.jenkins.id
  subnet_id       = each.value
  security_groups = [aws_security_group.jenkins_efs.id]
}

# Security Group for EFS - allows Jenkins ECS tasks to access EFS via NFS protocol
resource "aws_security_group" "jenkins_efs" {
  name        = "${var.project_name}-jenkins-efs-sg"
  description = "Allow Jenkins ECS tasks to access EFS file system via NFS (port 2049)"
  vpc_id      = module.jenkins_vpc.vpc_id

  # Allow inbound NFS traffic from Jenkins ECS tasks
  ingress {
    description     = "NFS from Jenkins ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.jenkins_ecs.ecs_tasks_security_group_id]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-jenkins-efs-sg"
  })
}

# EFS Access Point for Jenkins (optional - provides a specific directory and permissions)
# This creates a dedicated mount point with proper ownership for Jenkins user (UID 1000)
resource "aws_efs_access_point" "jenkins" {
  file_system_id = aws_efs_file_system.jenkins.id

  # Root directory for Jenkins data
  root_directory {
    path = "/jenkins_home"

    # Create directory with these settings if it doesn't exist
    creation_info {
      owner_gid   = 1000 # Jenkins group ID
      owner_uid   = 1000 # Jenkins user ID
      permissions = "755"
    }
  }

  # POSIX user settings for accessing the file system
  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-jenkins-access-point"
  })
}

# Output EFS details for use by ECS module
output "jenkins_efs_id" {
  description = "EFS file system ID for Jenkins"
  value       = aws_efs_file_system.jenkins.id
}

output "jenkins_efs_access_point_id" {
  description = "EFS access point ID for Jenkins"
  value       = aws_efs_access_point.jenkins.id
}
