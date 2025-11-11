# Broken Cloud Pipeline - AWS Infrastructure

This project implements a deliberately flawed cloud deployment pipeline on AWS (eu-central-1) using Terraform, Jenkins, and Linux/Bash/Python scripts.

## Architecture Overview

- **Application VPC**: 10.40.0.0/16 with 4 subnets (2 public, 2 private)
- **Jenkins VPC**: 10.41.0.0/16 with 4 subnets (2 public, 2 private)
- **VPC Peering**: Enabled between both VPCs
- **ECS Clusters**: Deployed in private subnets with 2 t3.micro instances each
- **Application**: 2 containers (infrastructureascode/hello-world) per cluster
- **Jenkins**: 1 container (jenkins/jenkins:lts) per cluster
- **Load Balancers**: ALBs for application and Jenkins (HTTPS only)
- **Monitoring**: Route53 health checks, CloudWatch alarms, SNS notifications

## Project Structure

```
.
├── terraform/
│   ├── modules/
│   │   └── ecs-cluster/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── jenkins/
│   └── Jenkinsfile
├── scripts/
│   └── verify_health.sh
└── README.md
```


## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Access to AWS eu-central-1 region
- Email address for SNS subscription confirmation

## Deployment

1. Initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

2. Review and customize variables:
   ```bash
   terraform plan
   ```

3. Deploy infrastructure:
   ```bash
   terraform apply
   ```

4. Configure Jenkins:
   - Access Jenkins via the ALB endpoint
   - Install required plugins
   - Configure email notifications
   - Load the Jenkinsfile pipeline

5. Subscribe to SNS topic for email notifications

## Cost Optimization

- Uses t3.micro instances (free tier eligible)
- Minimal resource allocation
- S3 lifecycle policies for log retention

## Security

- **HTTPS only (port 443)**: All inbound traffic restricted to HTTPS
- **Network ACLs**: Block non-HTTPS inbound traffic at the subnet level
- **Security Groups**:
  - Application ALB: Allow HTTPS inbound (port 443), open to all
  - Jenkins ALB: Allow HTTPS inbound (port 443), restricted to Portugal IP ranges
  - Outbound: Allow all traffic
- **WAF Geo-Restriction**: Jenkins ALB protected by AWS WAF with IP-based geo-restriction to Portugal
- **ECS tasks in private subnets**: No direct internet access
- **IAM roles with least privilege**: Minimal permissions for each role

## Monitoring

- **Route53 health checks** on ALB endpoints
- **CloudWatch alarms** for:
  - HTTP 5xx errors on both ALBs
  - Route53 health check failures
  - Daily AWS costs exceeding $1
- **SNS notifications** for all alarm states (subscription confirmation required)
- **S3 access logging** enabled for ALB logs
- **WAF metrics** in CloudWatch for geo-restriction monitoring

## Notes

- All infrastructure deployed in eu-central-1 (Frankfurt)
- VPC peering enables cross-VPC communication
- ECR repository for custom container images
- CloudWatch logs for ECS tasks
