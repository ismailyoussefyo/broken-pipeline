# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ${var.cluster_name} ALB"
  vpc_id      = var.vpc_id

  # Only allow HTTPS traffic
  ingress {
    description = "HTTPS from allowed CIDR blocks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-sg"
  })
}

# Security Group for ECS tasks
# Controls inbound/outbound traffic for ECS tasks running in the cluster
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-ecs-tasks-sg"
  description = "Security group for ${var.cluster_name} ECS tasks"
  vpc_id      = var.vpc_id

  # FLAW #1: Security group allows traffic from ALB but uses wrong port range
  # The ingress rule should only allow the container_port (e.g., 80), but it allows a wider range (80-180)
  # This creates an unnecessarily permissive security group rule that could allow access to additional ports
  # Impact: Security concern - allows potential access to ports beyond the intended container port
  # Fix: Change to_port = var.container_port + 100 to to_port = var.container_port
  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port + 100 # FLAW: Should be var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-tasks-sg"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = var.s3_logging_bucket
    enabled = true
    prefix  = "${var.cluster_name}-alb"
  }

  tags = merge(var.tags, {
    Name = var.alb_name
  })
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.cluster_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-tg"
  })
}

# HTTPS Listener - only allow HTTPS traffic
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

# Get latest Amazon Linux 2 ECS optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_instances" {
  name        = "${var.cluster_name}-ec2-sg"
  description = "Security group for ${var.cluster_name} EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ECS tasks security group"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ec2-sg"
  })
}

# Launch Template for EC2 instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [aws_security_group.ec2_instances.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config

    # Fix Docker socket permissions for Jenkins containers
    chmod 666 /var/run/docker.sock
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-ec2-instance"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-launch-template"
  })
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.cluster_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ec2-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.cluster_name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }

    managed_termination_protection = "DISABLED"
  }
}

# Attach capacity provider to cluster
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.cluster_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = var.container_image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    # Mount Docker socket for Jenkins to enable Docker-in-Docker
    # Mount EFS volume for Jenkins persistent storage
    mountPoints = concat(
      var.is_jenkins ? [{
        sourceVolume  = "docker_sock"
        containerPath = "/var/run/docker.sock"
        readOnly      = false
      }] : [],
      var.efs_file_system_id != "" ? [{
        sourceVolume  = "jenkins_home"
        containerPath = "/var/jenkins_home"
        readOnly      = false
      }] : []
    )

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = var.is_jenkins ? [
      {
        name  = "JENKINS_OPTS"
        value = "--httpPort=8080"
      }
    ] : []
  }])

  # Docker socket volume for Jenkins (enables Docker-in-Docker)
  dynamic "volume" {
    for_each = var.is_jenkins ? [1] : []
    content {
      name      = "docker_sock"
      host_path = "/var/run/docker.sock"
    }
  }

  # EFS volume for Jenkins persistent storage
  # Mounts /var/jenkins_home to EFS to persist Jenkins configuration, jobs, credentials, and build history
  dynamic "volume" {
    for_each = var.efs_file_system_id != "" ? [1] : []
    content {
      name = "jenkins_home"

      efs_volume_configuration {
        file_system_id          = var.efs_file_system_id
        transit_encryption      = "ENABLED"
        authorization_config {
          access_point_id = var.efs_access_point_id
          iam             = "ENABLED"
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-task"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "/ecs/${var.cluster_name}"
  })
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.cluster_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.container_count
  launch_type     = "EC2"

  # Deployment configuration to handle ENI resource constraints
  # Allow stopping old tasks before new ones start (blue-green deployment)
  deployment_minimum_healthy_percent = 50  # Can drop to 50% during deployment
  deployment_maximum_percent         = 100 # Never exceed desired count

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # Health check grace period - wait for containers to start before checking health
  health_check_grace_period_seconds = 300

  depends_on = [
    aws_autoscaling_group.ecs
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-service"
  })
}

# Route53 Record (only created if route53_zone_id is provided)
resource "aws_route53_record" "main" {
  count   = var.route53_zone_id != "" && var.route53_record_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Route53 Health Check (only created if route53_record_name is provided)
resource "aws_route53_health_check" "main" {
  count             = var.route53_record_name != "" ? 1 : 0
  fqdn              = var.route53_record_name
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-health-check"
  })
}

data "aws_region" "current" {}
