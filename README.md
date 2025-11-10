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

## Deliberate Flaws

This infrastructure contains **exactly three subtle flaws** that do not impair core functionality:

### Flaw #1: Terraform - Security Group Port Range (terraform/modules/ecs-cluster/main.tf)

**Location**: `terraform/modules/ecs-cluster/main.tf` lines 34-43

**Description**: The ECS tasks security group ingress rule allows a wider port range than necessary. Instead of only allowing traffic on `container_port`, it allows traffic from `container_port` to `container_port + 100`. This creates an unnecessarily permissive security group rule that could allow access to additional ports if containers are misconfigured.

**Impact**: Security concern - allows potential access to ports beyond the intended container port, but doesn't break functionality since the ALB only forwards to the correct port.

**Fix**: Change `to_port = var.container_port + 100` to `to_port = var.container_port`

### Flaw #2: Jenkins Pipeline - Missing Error Handling (jenkins/Jenkinsfile)

**Location**: `jenkins/Jenkinsfile` lines 15-22

**Description**: The Build stage executes Docker commands without checking return codes. If `docker build` fails, the pipeline continues to the next stage without failing, potentially pushing a broken image or deploying a failed build.

**Impact**: Pipeline may report success even when builds fail, leading to deployment of broken images.

**Fix**: Add error checking after docker commands:
```groovy
sh '''
    docker build -t ${APP_NAME}:${BUILD_NUMBER} . || exit 1
    docker tag ${APP_NAME}:${BUILD_NUMBER} ${ECR_REPO}:${BUILD_NUMBER} || exit 1
    docker tag ${APP_NAME}:${BUILD_NUMBER} ${ECR_REPO}:latest || exit 1
'''
```

### Flaw #3: Health Check Script - Incomplete Health Verification (scripts/verify_health.sh)

**Location**: `scripts/verify_health.sh` lines 37-49

**Description**: The health check script only verifies that the container is running (process check) but never actually tests the HTTP health endpoint. The script accepts `HEALTH_CHECK_URL` as a parameter but never uses it to make an HTTP request. A container can be running but still failing to serve requests correctly.

**Impact**: Health checks may pass even when the application is not responding correctly to HTTP requests, leading to false positives in deployment verification.

**Fix**: Add actual HTTP endpoint check:
```bash
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_CHECK_URL")
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Health check passed: HTTP $HTTP_CODE"
else
    echo "Health check failed: HTTP $HTTP_CODE"
    exit 1
fi
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
