# EFS (Elastic File System) for Jenkins Persistent Storage
# This ensures Jenkins data survives container restarts

# EFS File System for Jenkins
resource "aws_efs_file_system" "jenkins" {
  creation_token = "${var.project_name}-jenkins-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-jenkins-efs"
    Description = "Persistent storage for Jenkins home directory"
  })
}

# Security Group for EFS
resource "aws_security_group" "efs_jenkins" {
  name        = "${var.project_name}-jenkins-efs-sg"
  description = "Security group for Jenkins EFS mount targets"
  vpc_id      = module.jenkins_vpc.vpc_id

  # Allow NFS traffic from Jenkins VPC (ECS tasks are in private subnets)
  ingress {
    description = "NFS from Jenkins VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.jenkins_vpc.vpc_cidr_block]
  }

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

# EFS Mount Targets (one per private subnet for high availability)
resource "aws_efs_mount_target" "jenkins" {
  count = length(module.jenkins_vpc.private_subnets)

  file_system_id  = aws_efs_file_system.jenkins.id
  subnet_id       = module.jenkins_vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs_jenkins.id]
}

# EFS Access Point for Jenkins (provides a specific entry point)
resource "aws_efs_access_point" "jenkins" {
  file_system_id = aws_efs_file_system.jenkins.id

  root_directory {
    path = "/jenkins"
    creation_info {
      owner_gid   = 1000  # Jenkins user GID
      owner_uid   = 1000  # Jenkins user UID
      permissions = "755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-jenkins-access-point"
  })
}

