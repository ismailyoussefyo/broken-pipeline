# Jenkins Pipeline Setup and Testing Guide

## Overview
Jenkins automates the complete CI/CD pipeline: Build → Test → Push to ECR → Deploy to ECS → Verify → Notify

## Quick Test (5 minutes)

### 1. Access Jenkins
- URL: `<YOUR_JENKINS_ALB_URL>`
- Initial Password: Get from ECS logs or Jenkins container

### 2. Complete Initial Setup
1. Install suggested plugins (or select Docker Pipeline, AWS plugins)
2. Create admin user
3. Save and continue

### 3. Configure AWS Credentials
1. Go to: **Manage Jenkins** → **Manage Credentials** → **System** → **Global credentials**
2. Add credentials:
   - Kind: **AWS Credentials**
   - ID: `aws-credentials`
   - Access Key ID: `<YOUR_AWS_ACCESS_KEY_ID>`
   - Secret Access Key: `<YOUR_AWS_SECRET_ACCESS_KEY>`

3. Add ECR Repository URL:
   - Kind: **Secret text**
   - ID: `ecr-repo-url`
   - Secret: `<YOUR_ECR_REPOSITORY_URL>`

### 4. Create Pipeline Job
1. Click **New Item**
2. Name: `broken-pipeline`
3. Type: **Pipeline**
4. Click **OK**

### 5. Configure Pipeline
In the Pipeline configuration:

**Pipeline Definition:**
- Select: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: Your Git repository URL (or use "Pipeline script" and paste Jenkinsfile content)
- Script Path: `jenkins/Jenkinsfile`

**OR** for quick testing without Git:
- Select: **Pipeline script**
- Copy content from `/Users/ismailyoussef/challenge/jenkins/Jenkinsfile`
- Paste into the script box

### 6. Add Environment Variables
In Pipeline configuration, add:
- `EMAIL_RECIPIENTS`: `ismailmostafa.y@gmail.com`

### 7. Run Pipeline
1. Click **Build Now**
2. Watch the pipeline stages execute
3. Check console output for logs

## Expected Pipeline Flow

```
┌─────────────────────────────────────────────┐
│ 1. Checkout                                 │
│    → Pull code from Git repository          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 2. Build (🐛 FLAW #2)                       │
│    → Build Docker image from Dockerfile     │
│    → Missing error handling                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 3. Test (🐛 FLAW #3)                        │
│    → Run verify_health.sh                   │
│    → Script doesn't check HTTP endpoint     │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 4. Push to ECR                              │
│    → Push image to ECR repository           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 5. Deploy                                   │
│    → Update ECS service                     │
│    → Force new deployment                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 6. Verify                                   │
│    → Check deployment status                │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│ 7. Notify (SNS Email)                       │
│    → Send success/failure notification      │
└─────────────────────────────────────────────┘
```

## Testing the Complete Flow

### Option A: Simple Test (Without Git)
1. Set up Jenkins with credentials (steps 1-3 above)
2. Create a Pipeline job with "Pipeline script"
3. Paste the Jenkinsfile content
4. Modify to skip Git checkout:
   ```groovy
   stage('Checkout') {
       steps {
           echo 'Skipping checkout for manual test'
       }
   }
   ```
5. Build manually

### Option B: Full Test (With Git)
1. Push your code to GitHub/GitLab
2. Configure Jenkins with Git repository URL
3. Set up webhook for automatic builds
4. Push a change to trigger pipeline

### Option C: Quick Verification (Current Setup)
Since Docker isn't available in the Jenkins container and we're using a public image, you can verify Jenkins is working by:

1. **Create a simple test pipeline:**
   ```groovy
   pipeline {
       agent any
       stages {
           stage('Test AWS Access') {
               steps {
                   echo 'Testing AWS access...'
                   sh 'aws sts get-caller-identity'
               }
           }
           stage('Test ECR') {
               steps {
                   echo 'Testing ECR repository access...'
                   sh 'aws ecr describe-repositories --region eu-central-1'
               }
           }
           stage('Test ECS') {
               steps {
                   echo 'Testing ECS cluster access...'
                   sh 'aws ecs describe-clusters --clusters broken-pipeline-app --region eu-central-1'
               }
           }
       }
   }
   ```

2. **This will test:**
   - ✅ Jenkins is running
   - ✅ AWS credentials work
   - ✅ Can access ECR
   - ✅ Can access ECS
   - ✅ Pipeline stages execute

## Current Limitation

The Jenkins container needs:
- Docker installed (to build images)
- Docker socket mounted (to run Docker commands)

**To use the full pipeline, you would need to:**
1. Create a custom Jenkins image with Docker installed
2. Update the ECS task definition to mount Docker socket
3. Or use a Jenkins agent with Docker capability

## Demonstrating the Flaws

### Flaw #2: Missing Error Handling (Build Stage)
- The build stage doesn't check if `docker build` succeeds
- If the Dockerfile has errors, pipeline continues anyway
- **Test:** Introduce a syntax error in Dockerfile, build should fail but pipeline reports success

### Flaw #3: Health Check Logic Error (Test Stage)
- `verify_health.sh` only checks if container is running
- Doesn't actually verify HTTP endpoint returns 200 OK
- **Test:** Container could be running but serving 500 errors, health check passes

## Summary

**Current State:**
- ✅ Jenkins is deployed and accessible
- ✅ Can create and run pipelines
- ⚠️  Full Docker pipeline needs Docker-in-Docker setup

**To Fully Test Challenge:**
1. Access Jenkins UI
2. Set up credentials
3. Create a simple test pipeline (Option C above)
4. Verify stages execute
5. Check AWS resources are accessible

**For Production Pipeline:**
- Would need Docker-in-Docker or separate build agent
- Would need Git repository configured
- Would need email notifications configured


