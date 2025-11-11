# ECS Cluster Configuration
# This file defines the ECS clusters for application and Jenkins using the reusable module

# Application ECS Cluster Module
# Deploys the hello-world application in the Application VPC (10.40.0.0/16)
# FLAW #1 Location: See terraform/modules/ecs-cluster/main.tf - Security group port range issue
module "app_ecs" {
  source = "./modules/ecs-cluster"

  cluster_name          = "${var.project_name}-app"
  vpc_id                = module.app_vpc.vpc_id
  private_subnet_ids    = module.app_vpc.private_subnets
  public_subnet_ids     = module.app_vpc.public_subnets
  container_image       = "${aws_ecr_repository.app.repository_url}:latest" # Custom built image from pipeline
  container_name        = "hello-world"
  container_count       = 2
  cpu                   = 256
  memory                = 256 # Reduced from 512 to fit on t2.micro
  container_port        = 80
  alb_name              = "${var.project_name}-app-alb"
  is_jenkins            = false
  allowed_cidr_blocks   = ["0.0.0.0/0"] # Application ALB open to all
  certificate_arn       = local.certificate_arn
  s3_logging_bucket     = aws_s3_bucket.alb_logs.id
  route53_zone_id       = local.route53_zone_id
  route53_record_name   = var.domain_name != "" ? "app.${var.domain_name}" : ""
  health_check_path     = "/"
  execution_role_arn    = aws_iam_role.ecs_execution.arn
  task_role_arn         = aws_iam_role.ecs_task.arn
  instance_profile_name = aws_iam_instance_profile.ec2_instance.name

  tags = var.tags
}

# Jenkins ECS Cluster Module
# Deploys Jenkins in the Jenkins VPC (10.41.0.0/16)
# Jenkins ALB is restricted to Portugal IPs via Security Groups and WAF
# EFS is attached for persistent storage (/var/jenkins_home)
module "jenkins_ecs" {
  source = "./modules/ecs-cluster"

  cluster_name          = "${var.project_name}-jenkins"
  vpc_id                = module.jenkins_vpc.vpc_id
  private_subnet_ids    = module.jenkins_vpc.private_subnets
  public_subnet_ids     = module.jenkins_vpc.public_subnets
  container_image       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/broken-pipeline-jenkins:latest"
  container_name        = "jenkins"
  container_count       = 1
  cpu                   = 256
  memory                = 512  # Reduced from 700 to fit on t3.micro (944MB available)
  container_port        = 8080
  alb_name              = "${var.project_name}-jenkins-alb"
  is_jenkins            = true
  allowed_cidr_blocks   = ["0.0.0.0/0"] # Jenkins ALB geo-restriction handled by WAF (PT, EG)
  certificate_arn       = local.certificate_arn
  s3_logging_bucket     = aws_s3_bucket.alb_logs.id
  route53_zone_id       = local.route53_zone_id
  route53_record_name   = var.domain_name != "" ? "jenkins.${var.domain_name}" : ""
  health_check_path     = "/login"
  execution_role_arn    = aws_iam_role.ecs_execution.arn
  task_role_arn         = aws_iam_role.ecs_task.arn
  instance_profile_name = aws_iam_instance_profile.ec2_instance.name

  # EFS configuration for persistent Jenkins storage
  efs_file_system_id  = aws_efs_file_system.jenkins.id
  efs_access_point_id = aws_efs_access_point.jenkins.id

  tags = var.tags
}
