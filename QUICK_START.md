# Jenkins Pipeline - Quick Start (5 Minutes)

## 🚀 Fastest Way to Get Your Pipeline Running

### Step 1: Add AWS Credentials (2 minutes)

1. Jenkins UI → **Manage Jenkins** → **Manage Credentials** → **Global**
2. **Add Credentials** → Select **AWS Credentials**:
   - ID: `aws-credentials`
   - Access Key: Your AWS Access Key
   - Secret Key: Your AWS Secret Key

3. **Add Credentials** → Select **Secret text**:
   - ID: `ecr-repo-url`
   - Secret: Get with this command:
   ```bash
   aws ecr describe-repositories --repository-names broken-pipeline-app --region eu-central-1 --query 'repositories[0].repositoryUri' --output text
   ```

### Step 2: Configure Email (2 minutes)

1. **Manage Jenkins** → **Configure System** → **Extended E-mail Notification**:
   - SMTP server: `smtp.gmail.com`
   - SMTP Port: `587`
   - Username: `ismailmostafa.y@gmail.com`
   - Password: [Get App Password from https://myaccount.google.com/apppasswords]
   - ✅ Use TLS

### Step 3: Create Pipeline (1 minute)

1. **New Item** → Name: `broken-pipeline-app` → Type: **Pipeline**
2. In **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/ismailyoussefyo/broken-pipeline.git`
   - Branch: `*/main`
   - Script Path: Choose one:
     - `jenkins/SimplifiedPipeline.groovy` ← **START HERE (Works immediately)**
     - `jenkins/Jenkinsfile` (Needs Docker-in-Docker setup)

3. **Save**

### Step 4: Run Pipeline

1. Click **Build Now**
2. Watch it run
3. Check your email for results

---

## That's It! 🎉

Your pipeline will:
- ✅ Checkout code from GitHub
- ✅ Validate AWS access
- ✅ Deploy to ECS
- ✅ Verify deployment
- ✅ Email you the results

---

## Troubleshooting

**Can't find credentials?**
- Make sure IDs are exactly: `aws-credentials` and `ecr-repo-url`

**Email not sending?**
- Use Gmail App Password, not your regular password
- Enable 2FA on Google account first

**Build fails?**
- Check Console Output in Jenkins
- Verify AWS credentials have correct permissions


---

## Quick Commands

```bash
# Get ECR repository URL
aws ecr describe-repositories --repository-names broken-pipeline-app --region eu-central-1 --query 'repositories[0].repositoryUri' --output text

# Get ALB endpoint
aws elbv2 describe-load-balancers --region eu-central-1 --query 'LoadBalancers[?contains(LoadBalancerName, `app-alb`)].DNSName' --output text

# Check ECS service
aws ecs describe-services --cluster broken-pipeline-app --services broken-pipeline-app-service --region eu-central-1
```
