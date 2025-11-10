# Running the Rebuilt Pipeline

## Pipeline Overview

The Jenkins pipeline now implements all challenge requirements:

### Pipeline Stages (in order):

1. **Checkout** - Pull source code from GitHub
2. **Build Docker Image** - Build from Dockerfile with timestamp-based tag
3. **Health Check** - Verify container starts (Flaw #3: No HTTP test)
4. **Push to ECR** - Push image with timestamp tag and :latest
5. **Update Infrastructure** - Run Terraform (only if .tf files changed)
6. **Deploy to ECS** - Force new deployment
7. **Verify Deployment** - Wait 30s for stabilization
8. **Log to S3** - Store logs (Flaw #4: Uploads too much)
9. **Notify SNS** - Send deployment notification

---

## Prerequisites

Before running the pipeline, ensure you have:

### 1. Jenkins Credentials

- `github-credentials` - GitHub Personal Access Token
- `aws-access-key-id` - AWS Access Key ID (Secret text)
- `aws-secret-access-key` - AWS Secret Access Key (Secret text)

### 2. AWS Resources (via Terraform)

```bash
cd terraform
terraform apply
```

This creates:
- ✅ ECR repository: `broken-pipeline-app`
- ✅ ECS cluster: `broken-pipeline-app`
- ✅ ECS service: `broken-pipeline-app-service`
- ✅ S3 bucket: `broken-pipeline-app-logs-<account-id>`
- ✅ SNS topic: `broken-pipeline-alarms`
- ✅ EFS volume for Jenkins persistence

### 3. Email Configuration (Optional)

Configure SMTP in Jenkins for email notifications:
- **Manage Jenkins** → **Configure System** → **Extended E-mail Notification**
- SMTP server: `smtp.gmail.com:587`
- Use SSL/TLS
- Credentials: Your email + App Password

---

## Running the Pipeline

### Method 1: Manual Trigger

1. Go to Jenkins: `http://<jenkins-alb-url>`
2. Click on your pipeline job
3. Click **"Build Now"**
4. Monitor progress in **"Build History"**

### Method 2: Git Push Trigger

1. Make a code change:
   ```bash
   echo "<!-- Updated -->" >> Dockerfile
   git add Dockerfile
   git commit -m "Trigger pipeline"
   git push origin main
   ```

2. Jenkins will automatically detect the change and start the build

---

## What Happens During Build

### Build Docker Image (Timestamp Tag)
```bash
IMAGE_TAG=$(date +%Y%m%d%H%M)  # Example: 202511101530
docker build -t hello-world:202511101530 .
```

### Push to ECR
```bash
ECR_REPO_URI=123456789012.dkr.ecr.eu-central-1.amazonaws.com/broken-pipeline-app
docker tag hello-world:202511101530 ${ECR_REPO_URI}:202511101530
docker tag hello-world:202511101530 ${ECR_REPO_URI}:latest
docker push ${ECR_REPO_URI}:202511101530
docker push ${ECR_REPO_URI}:latest
```

### Deploy to ECS
```bash
aws ecs update-service \
  --cluster broken-pipeline-app \
  --service broken-pipeline-app-service \
  --force-new-deployment
```

ECS will:
1. Pull `:latest` image from ECR
2. Start new tasks with new image
3. Drain and stop old tasks
4. Update ALB target group

### Log to S3 (with Cost Flaw)
```bash
# WARNING: Uploads entire Jenkins jobs directory (FLAW #4)
aws s3 cp /var/jenkins_home/jobs/ \
  s3://broken-pipeline-app-logs-<account-id>/pipeline-logs/${JOB_NAME}/${BUILD_TAG}/ \
  --recursive
```

### Send SNS Notification
```bash
aws sns publish \
  --topic-arn arn:aws:sns:eu-central-1:xxx:broken-pipeline-alarms \
  --message "Deployment completed with status: SUCCESS" \
  --subject "Deployment Result: SUCCESS"
```

---

## Verifying Deployment

### 1. Check ECS Service
```bash
aws ecs describe-services \
  --cluster broken-pipeline-app \
  --services broken-pipeline-app-service \
  --region eu-central-1
```

Look for:
- `runningCount: 2`
- `desiredCount: 2`
- Latest `taskDefinition` revision

### 2. Check Application Endpoint
```bash
# Get ALB DNS name
aws elbv2 describe-load-balancers \
  --names broken-pipeline-app-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text

# Test endpoint
curl http://<alb-dns-name>
```

You should see the custom Nginx welcome page with pipeline information.

### 3. Check S3 Logs
```bash
aws s3 ls s3://broken-pipeline-app-logs-$(aws sts get-caller-identity --query Account --output text)/pipeline-logs/ --recursive
```

### 4. Check SNS Email
Check your email for deployment notification (if SNS email subscription is confirmed).

---

## Pipeline Outputs

### Success Email
You'll receive an email with:
- ✅ Build information (job name, build number, URL)
- ✅ All 9 stages completed
- ✅ Deployment details (cluster, service, image tag)
- 📧 Sent to: `ismailmostafa.y@gmail.com`

### Jenkins Console Output
```
========================================
Building custom Docker image
Dockerfile: ./Dockerfile
Build Number: 15
========================================
Image Tag: 202511101530
...
✅ Images pushed successfully!
  - 123456789012.dkr.ecr.eu-central-1.amazonaws.com/broken-pipeline-app:202511101530
  - 123456789012.dkr.ecr.eu-central-1.amazonaws.com/broken-pipeline-app:latest
========================================
```

---

## Troubleshooting

### Pipeline Fails at "Build Docker Image"
```bash
# Check Dockerfile syntax
docker build -t test .

# Check Docker is available in Jenkins
docker --version
```

### Pipeline Fails at "Push to ECR"
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check ECR repository exists
aws ecr describe-repositories --repository-names broken-pipeline-app
```

### Pipeline Fails at "Deploy to ECS"
```bash
# Check ECS cluster exists
aws ecs describe-clusters --clusters broken-pipeline-app

# Check ECS service exists
aws ecs describe-services --cluster broken-pipeline-app --services broken-pipeline-app-service
```

### Pipeline Fails at "Log to S3"
```bash
# Check S3 bucket exists
aws s3 ls | grep broken-pipeline-app-logs

# Check IAM permissions for S3 upload
aws iam get-user
```

### Pipeline Fails at "Notify SNS"
```bash
# Check SNS topic exists
aws sns list-topics | grep broken-pipeline-alarms

# Verify SNS permissions
aws sns get-topic-attributes --topic-arn <topic-arn>
```

### No Email Received
1. Check spam/junk folder
2. Verify SMTP configuration in Jenkins
3. Test email by clicking **"Test configuration by sending test e-mail"**
4. Check Jenkins logs: **Manage Jenkins** → **System Log**

---

## Cleanup

### Stop Pipeline Jobs
```bash
# Delete Jenkins job (from Jenkins UI)
# Or stop all running builds
```

### Destroy AWS Resources
```bash
cd terraform
terraform destroy
```

This will remove:
- ECS cluster and services
- ECR repositories (and images)
- S3 buckets (logs)
- SNS topics
- ALB and target groups
- VPC and networking
- EFS volume (Jenkins data will be lost!)

### Preserve Jenkins Data
If you want to keep Jenkins configuration:
1. Backup EFS data before destroying
2. Or exclude EFS from destruction:
   ```bash
   terraform destroy -target=module.app_ecs
   # Keep Jenkins resources
   ```

---

## Next Steps

1. **Identify the 4 Flaws** - See `PIPELINE_FLAWS.md`
2. **Fix the Flaws** - Create a pull request with fixes
3. **Run Pre-Commit Hooks** - Set up `.pre-commit-config.yaml`
4. **Add Monitoring** - CloudWatch alarms are already configured
5. **Improve Health Checks** - Add proper HTTP endpoint testing

---

*For detailed flaw documentation, see `PIPELINE_FLAWS.md`*

