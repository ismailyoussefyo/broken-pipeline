# Deployment Guide

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Terraform** >= 1.0 installed
4. **Domain Name** for Route53 (or use a test domain)
5. **Email Address** for SNS notifications

## Step-by-Step Deployment

### 1. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: eu-central-1
# Default output format: json
```

### 2. Prepare Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

Required variables:
- `domain_name`: A domain you own (or use a test domain)
- `email_address`: Your email for SNS notifications

### 3. Initialize Terraform

```bash
terraform init
```

This will download the required providers and modules.

### 4. Plan the Deployment

```bash
terraform plan
```

Review the planned changes. You should see:
- 2 VPCs (Application and Jenkins) with 4 subnets each
- Network ACLs for both VPCs
- VPC peering connection
- ECS clusters with EC2 instances (2 t3.micro per cluster)
- Application Load Balancers (HTTPS only)
- WAF Web ACL for Jenkins ALB geo-restriction
- Route53 hosted zone and records
- S3 bucket for ALB logs
- ECR repository
- SNS topic
- CloudWatch alarms (including cost alarm)
- IAM roles and policies

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This will take approximately 10-15 minutes.

### 6. Configure ACM Certificate

After deployment, you'll need to validate the ACM certificate:

1. Go to AWS Console → Certificate Manager
2. Find your certificate
3. Create DNS validation records in Route53
4. Wait for validation (can take a few minutes)

**Note**: For a production environment, use a proper SSL certificate. For testing, you can use a self-signed certificate or skip HTTPS temporarily.

### 7. Subscribe to SNS Topic

1. Check your email for the SNS subscription confirmation
2. Click the confirmation link
3. You'll now receive CloudWatch alarm notifications including:
   - HTTP 5xx errors
   - Route53 health check failures
   - Daily cost alerts (> $1/day)

**Note**: Cost alarms require billing metrics to be enabled. This may take up to 24 hours to start working.

### 8. Configure Jenkins

1. Access Jenkins via the Route53 record: `https://jenkins.<your-domain>`
   - Or use the ALB DNS name from Terraform outputs
2. Get the initial admin password:
   ```bash
   # Get Jenkins container logs
   aws ecs list-tasks --cluster broken-pipeline-jenkins
   aws logs get-log-events --log-group-name /ecs/broken-pipeline-jenkins --log-stream-name <stream-name>
   ```
3. Install recommended plugins
4. Create an admin user
5. Configure email notifications (Settings → Configure System → E-mail Notification)
6. Install required plugins:
   - Docker Pipeline
   - AWS Steps
   - Email Extension

### 9. Configure Jenkins Credentials

1. Go to Jenkins → Manage Jenkins → Credentials
2. Add AWS credentials:
   - Kind: AWS Credentials
   - ID: `aws-credentials`
   - Access Key ID and Secret Access Key
3. Add ECR repository URL:
   - Kind: Secret text
   - ID: `ecr-repo-url`
   - Secret: Your ECR repository URL (from Terraform outputs)

### 10. Create Jenkins Pipeline

1. Create a new Pipeline job
2. Configure:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your Git repository
   - Script Path: `jenkins/Jenkinsfile`
3. Set environment variables:
   - `EMAIL_RECIPIENTS`: Your email address

### 11. Test the Pipeline

1. Trigger the pipeline manually
2. Monitor the build
3. Check email notifications
4. Verify deployment:
   ```bash
   curl https://app.<your-domain>
   ```

## Verification Checklist

- [ ] Both VPCs created with correct CIDR ranges (10.40.0.0/16 and 10.41.0.0/16)
- [ ] Network ACLs configured to block non-HTTPS traffic
- [ ] VPC peering connection established
- [ ] ECS clusters running with 2 EC2 instances each
- [ ] Application containers running (2 instances)
- [ ] Jenkins container running (1 instance)
- [ ] ALBs accessible via HTTPS only
- [ ] WAF geo-restriction active on Jenkins ALB (Portugal only)
- [ ] Route53 health checks passing
- [ ] CloudWatch alarms configured (including cost alarm)
- [ ] SNS topic subscribed
- [ ] S3 bucket receiving ALB logs
- [ ] Jenkins pipeline can build and deploy

## Troubleshooting

### ECS Tasks Not Starting

- Check EC2 instances are running: `aws ec2 describe-instances`
- Check ECS cluster capacity: `aws ecs describe-clusters --clusters broken-pipeline-app`
- Review CloudWatch logs: `/ecs/broken-pipeline-app`

### ALB Health Checks Failing

- Verify security groups allow traffic
- Check target group health: AWS Console → EC2 → Target Groups
- Review container logs in CloudWatch

### Route53 Health Checks Failing

- Ensure ACM certificate is validated
- Verify ALB is accessible
- Check health check configuration

### Jenkins Not Accessible

- Verify security group allows Portugal IPs (or your IP)
- Check ALB target group health
- Review Jenkins container logs

## Cost Estimation

Approximate monthly costs (Frankfurt region):
- 4x t3.micro EC2 instances: ~$30 (free tier eligible for first year)
- 2x Application Load Balancers: ~$35
- NAT Gateway: ~$35
- Data transfer: Variable
- S3 storage: Minimal (~$1)
- Route53: ~$0.50 per hosted zone
- CloudWatch: Minimal (~$1)

**Total**: ~$100-150/month (or ~$0-30/month with free tier)

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

**Warning**: This will delete all resources. Make sure you have backups if needed.

