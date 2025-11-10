# Jenkins Pipeline Setup - Step by Step Guide

## 🚀 Complete Setup Guide for Broken Pipeline Jenkins

### Prerequisites
- ✅ Jenkins UI is accessible
- ✅ AWS infrastructure deployed via Terraform
- ✅ ECR repository exists
- ✅ ECS cluster is running

---

## Step 1: Initial Jenkins Setup

### 1.1 Unlock Jenkins
1. Get the initial admin password from ECS container logs:
   ```bash
   # Get the task ID
   aws ecs list-tasks --cluster broken-pipeline-jenkins --region eu-central-1
   
   # Get logs (replace TASK_ID)
   aws ecs describe-tasks --cluster broken-pipeline-jenkins --tasks TASK_ID --region eu-central-1
   
   # Or check CloudWatch Logs
   # Log group: /ecs/broken-pipeline-jenkins
   ```

2. Enter the password in Jenkins UI

### 1.2 Install Plugins
Choose **"Install suggested plugins"** OR manually select these essential plugins:
- ✅ Git plugin
- ✅ Pipeline plugin
- ✅ Docker plugin
- ✅ Amazon ECR plugin
- ✅ AWS Steps plugin
- ✅ Email Extension Plugin (Email-ext)
- ✅ CloudBees AWS Credentials

### 1.3 Create Admin User
- Username: `admin` (or your choice)
- Password: (your secure password)
- Full name: Your name
- Email: `ismailmostafa.y@gmail.com`

---

## Step 2: Configure AWS Credentials in Jenkins

### 2.1 Add AWS Access Keys
1. Go to: **Manage Jenkins** → **Manage Credentials** → **System** → **Global credentials (unrestricted)**
2. Click **Add Credentials**
3. Configure:
   - **Kind**: `AWS Credentials`
   - **ID**: `aws-credentials` (IMPORTANT: Use exactly this ID)
   - **Description**: `AWS credentials for ECR and ECS`
   - **Access Key ID**: `<YOUR_AWS_ACCESS_KEY_ID>`
   - **Secret Access Key**: `<YOUR_AWS_SECRET_ACCESS_KEY>`
4. Click **OK**

### 2.2 Add ECR Repository URL
1. Click **Add Credentials** again
2. Configure:
   - **Kind**: `Secret text`
   - **Scope**: `Global`
   - **Secret**: `<YOUR_ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/broken-pipeline-app`
   - **ID**: `ecr-repo-url` (IMPORTANT: Use exactly this ID)
   - **Description**: `ECR Repository URL`
3. Click **OK**

**To get your ECR repository URL:**
```bash
aws ecr describe-repositories --repository-names broken-pipeline-app --region eu-central-1 --query 'repositories[0].repositoryUri' --output text
```

---

## Step 3: Configure Email Notifications

### 3.1 Configure SMTP Server
1. Go to: **Manage Jenkins** → **Configure System**
2. Scroll to **Extended E-mail Notification** section:
   - **SMTP server**: `smtp.gmail.com` (or your mail server)
   - **SMTP Port**: `587`
   - **Click "Advanced"**:
     - ✅ Check **Use SMTP Authentication**
     - **User Name**: `ismailmostafa.y@gmail.com`
     - **Password**: Your Gmail App Password (NOT regular password)
     - ✅ Check **Use TLS**
3. **Default Recipients**: `ismailmostafa.y@gmail.com`

### 3.2 Configure Standard Email
Scroll down to **E-mail Notification** section:
   - **SMTP server**: `smtp.gmail.com`
   - **Click "Advanced"**:
     - ✅ Check **Use SMTP Authentication**
     - **User Name**: `ismailmostafa.y@gmail.com`
     - **Password**: Your Gmail App Password
     - ✅ Check **Use SSL**
     - **SMTP Port**: `465`
     
4. Click **Test configuration by sending test e-mail**
5. Click **Save**

**Gmail App Password:**
- Go to: https://myaccount.google.com/apppasswords
- Create an app password for "Jenkins"
- Use this password (NOT your Gmail password)

---

## Step 4: Create the Pipeline Job

### 4.1 Create New Pipeline
1. From Jenkins Dashboard, click **New Item**
2. Enter item name: `broken-pipeline-app`
3. Select: **Pipeline**
4. Click **OK**

### 4.2 Configure General Settings
In the pipeline configuration page:

**Description:**
```
Automated CI/CD pipeline for hello-world application
- Builds Docker image
- Runs health checks
- Pushes to ECR
- Deploys to ECS
- Sends email notifications
```

**Build Triggers:**
- ⬜ Do NOT check any triggers (manual only for now)
- Later you can add: ✅ GitHub hook trigger for GITScm polling

---

## Step 5: Configure Pipeline Source

### Option A: Pipeline from GitHub (Recommended)

1. In **Pipeline** section:
   - **Definition**: Select `Pipeline script from SCM`
   - **SCM**: Select `Git`
   - **Repository URL**: `https://github.com/ismailyoussefyo/broken-pipeline.git`
   - **Credentials**: (leave as "none" for public repo)
   - **Branch Specifier**: `*/main`
   - **Script Path**: `jenkins/Jenkinsfile`

2. Click **Save**

### Option B: Inline Pipeline Script (For Testing)

1. In **Pipeline** section:
   - **Definition**: Select `Pipeline script`
   - **Script**: Copy and paste the entire Jenkinsfile content

2. You'll need to modify the Checkout stage:
   ```groovy
   stage('Checkout') {
       steps {
           echo 'Using inline script - checkout not needed'
           // Skip git checkout since we're using inline script
       }
   }
   ```

3. Click **Save**

---

## Step 6: Add Environment Variables

1. In the pipeline configuration, scroll to **Pipeline** section
2. Before the script box, you can add environment variables OR
3. Edit the Jenkinsfile to hardcode them (not recommended) OR
4. Better: Configure them in Jenkins:

**Method 1: In Jenkinsfile (already configured)**
The Jenkinsfile already has these:
```groovy
environment {
    AWS_REGION = 'eu-central-1'
    ECR_REPO = credentials('ecr-repo-url')
    APP_NAME = 'hello-world'
    EMAIL_RECIPIENTS = 'ismailmostafa.y@gmail.com'  // Add this line
}
```

**Method 2: Global Environment Variables**
1. Go to: **Manage Jenkins** → **Configure System**
2. Scroll to **Global properties**
3. ✅ Check **Environment variables**
4. Click **Add**:
   - **Name**: `EMAIL_RECIPIENTS`
   - **Value**: `ismailmostafa.y@gmail.com`
5. Click **Save**

---

## Step 7: Update the Jenkinsfile

You need to add the EMAIL_RECIPIENTS to your Jenkinsfile. Update the environment section:

```groovy
environment {
    AWS_REGION = 'eu-central-1'
    ECR_REPO = credentials('ecr-repo-url')
    APP_NAME = 'hello-world'
    EMAIL_RECIPIENTS = 'ismailmostafa.y@gmail.com'  // ADD THIS LINE
}
```

---

## Step 8: Run the Pipeline (Manual Trigger)

### 8.1 First Test Run
1. Go to your pipeline: **Dashboard** → **broken-pipeline-app**
2. Click **Build Now** (left sidebar)
3. Watch the pipeline execute in real-time
4. Click on the build number (e.g., #1) to see details
5. Click **Console Output** to see logs

### 8.2 Expected Pipeline Stages
```
✓ Checkout          - Pull code from Git
✓ Build            - Build Docker image (⚠️ FLAW #2)
✓ Test             - Run health checks (⚠️ FLAW #3)
✓ Push to ECR      - Push image to ECR
✓ Deploy           - Deploy to ECS
✓ Verify           - Verify deployment
✓ Notify           - Send email notification
```

### 8.3 Monitor Pipeline Execution
- **Blue Ocean UI** (better visualization): Install Blue Ocean plugin
- **Stage View**: Shows each stage status
- **Console Output**: Shows detailed logs

---

## Step 9: Verify Pipeline Success

### 9.1 Check Email Notification
You should receive an email with:
- **Subject**: `Pipeline SUCCESS: broken-pipeline-app - #1`
- **Body**: Build details and link

### 9.2 Verify ECS Deployment
```bash
# Check ECS service
aws ecs describe-services \
  --cluster broken-pipeline-app \
  --services broken-pipeline-app-service \
  --region eu-central-1

# Check running tasks
aws ecs list-tasks \
  --cluster broken-pipeline-app \
  --region eu-central-1
```

### 9.3 Verify Application
Get the ALB URL:
```bash
aws elbv2 describe-load-balancers \
  --region eu-central-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `app-alb`)].DNSName' \
  --output text
```

Visit: `http://<ALB_DNS_NAME>` - Should show hello-world page

---

## Step 10: Troubleshooting Common Issues

### Issue 1: "Docker command not found"
**Problem**: Jenkins container doesn't have Docker installed
**Solution**: 
- The current Jenkins setup runs in ECS Fargate without Docker
- You need to either:
  1. Use Docker-in-Docker (requires privileged mode)
  2. Use a Jenkins agent with Docker
  3. Use AWS CodeBuild instead

**Workaround for Testing**:
Create a simplified test pipeline that only does AWS operations:

```groovy
pipeline {
    agent any
    environment {
        AWS_REGION = 'eu-central-1'
    }
    stages {
        stage('Test AWS Access') {
            steps {
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials')]) {
                        sh 'aws sts get-caller-identity'
                        sh 'aws ecr describe-repositories --region ${AWS_REGION}'
                    }
                }
            }
        }
        stage('Deploy to ECS') {
            steps {
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials')]) {
                        sh '''
                            aws ecs update-service \
                                --cluster broken-pipeline-app \
                                --service broken-pipeline-app-service \
                                --force-new-deployment \
                                --region ${AWS_REGION}
                        '''
                    }
                }
            }
        }
    }
    post {
        success {
            emailext (
                subject: "Pipeline SUCCESS",
                body: "Deployment completed successfully",
                to: 'ismailmostafa.y@gmail.com'
            )
        }
    }
}
```

### Issue 2: "Credentials not found"
**Problem**: Credential IDs don't match
**Solution**: 
- Ensure credential IDs are exactly: `aws-credentials` and `ecr-repo-url`
- Check in: Manage Jenkins → Manage Credentials

### Issue 3: "Permission denied" for AWS operations
**Problem**: IAM permissions insufficient
**Solution**: 
- Ensure the ECS task role has permissions for:
  - ECR: `PullImage`, `PushImage`, `GetAuthorizationToken`
  - ECS: `UpdateService`, `DescribeServices`

### Issue 4: Email not sending
**Problem**: SMTP configuration incorrect
**Solution**:
- Use Gmail App Password (not regular password)
- Enable "Less secure apps" OR use App Password
- Check SMTP settings (port 587 for TLS, 465 for SSL)

---

## Step 11: Testing the Flaws

### Test Flaw #2: Build Error Handling
1. Modify Dockerfile to introduce an error:
   ```dockerfile
   FROM non-existent-image:latest
   ```
2. Run the pipeline
3. **Expected**: Pipeline should continue despite build failure (FLAW)
4. **After Fix**: Pipeline should fail at Build stage

### Test Flaw #3: Health Check
1. Deploy an image that starts but doesn't serve HTTP
2. Run health check script
3. **Expected**: Health check passes even though HTTP fails (FLAW)
4. **After Fix**: Health check should fail if HTTP endpoint doesn't return 200

---

## Quick Start Checklist

- [ ] Jenkins unlocked and configured
- [ ] AWS credentials added (`aws-credentials`)
- [ ] ECR repo URL added (`ecr-repo-url`)
- [ ] Email (SMTP) configured
- [ ] Pipeline job created
- [ ] Jenkinsfile loaded (from Git or inline)
- [ ] Environment variable `EMAIL_RECIPIENTS` set
- [ ] First build triggered manually
- [ ] Email notification received
- [ ] Application deployed and accessible

---

## Next Steps

1. **Set up automatic triggers**: Configure GitHub webhooks
2. **Add build parameters**: Make pipeline configurable
3. **Implement Docker-in-Docker**: For full build capability
4. **Add stages**: Unit tests, security scans, staging deployment
5. **Blue/Green deployment**: Zero-downtime deployments

---

## Useful Commands

```bash
# Get Jenkins initial password
aws logs tail /ecs/broken-pipeline-jenkins --region eu-central-1

# Get ECR login
aws ecr get-login-password --region eu-central-1

# Force ECS deployment
aws ecs update-service --cluster broken-pipeline-app --service broken-pipeline-app-service --force-new-deployment --region eu-central-1

# Check pipeline logs in CloudWatch
aws logs tail /ecs/broken-pipeline-jenkins --follow --region eu-central-1
```

---

## Summary

Your pipeline is now set up to:
1. ✅ Pull code from GitHub
2. ✅ Build Docker image (with intentional flaw)
3. ✅ Run health checks (with intentional flaw)
4. ✅ Push to ECR
5. ✅ Deploy to ECS
6. ✅ Send email notifications

**Manual Trigger**: Click "Build Now" in Jenkins UI
**Automatic Trigger**: Configure GitHub webhook (optional)

Good luck with your pipeline! 🚀

