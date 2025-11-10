# Deployment Readiness Checklist

## ✅ Code Structure - READY

- [x] All Terraform files organized by resource type
- [x] Dockerfile customizes infrastructureascode/hello-world
- [x] Jenkinsfile defines the pipeline
- [x] verify_health.sh script with flaw
- [x] Pre-commit configuration
- [x] Detect-secrets configuration
- [x] All three deliberate flaws documented

## ⚠️ Pre-Deployment Requirements

### 1. **AWS Account Setup** - REQUIRED
- [ ] AWS account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] AWS credentials configured (`aws configure`)
- [ ] Region set to `eu-central-1`

### 2. **Terraform Variables** - REQUIRED
- [ ] Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`
- [ ] Set `domain_name` (must be a domain you own or use a test domain)
- [ ] Set `email_address` (for SNS notifications)

**Required variables:**
```hcl
domain_name   = "your-domain.com"  # REQUIRED
email_address = "your-email@example.com"  # REQUIRED
```

### 3. **Domain Name** - REQUIRED
- [ ] You need a domain name for Route53 hosted zone
- [ ] Or use a test domain (will need to update DNS records manually)
- [ ] ACM certificate will require DNS validation

### 4. **Terraform Initialization** - REQUIRED
```bash
cd terraform
terraform init
```

### 5. **Pre-Commit Hooks** - OPTIONAL (Recommended)
```bash
pip install pre-commit
pre-commit install
detect-secrets scan > .secrets.baseline
```

## 🔍 Pre-Deployment Validation

### Run Terraform Validation:
```bash
cd terraform
terraform fmt -check
terraform validate
terraform plan
```

### Expected Resources (from terraform plan):
- 2 VPCs (Application and Jenkins)
- 8 Subnets (4 per VPC)
- 4 Network ACLs
- VPC Peering Connection
- 2 ECS Clusters
- 4 EC2 instances (2 per cluster, t3.micro)
- 2 Application Load Balancers
- 2 Target Groups
- WAF Web ACL for Jenkins
- 2 Route53 Health Checks
- 2 Route53 Records
- 1 Route53 Hosted Zone
- 1 ACM Certificate
- 2 S3 Buckets (ALB logs, application logs)
- 3 IAM Roles
- 1 IAM Instance Profile
- 1 ECR Repository
- 1 SNS Topic
- 5 CloudWatch Alarms

## ⚠️ Known Issues & Considerations

### 1. **ACM Certificate Validation**
- ACM certificate requires DNS validation
- After deployment, create DNS records in Route53 for validation
- Certificate validation may take 5-30 minutes

### 2. **Cost Alarm**
- Billing metrics may take up to 24 hours to start reporting
- Cost alarm may not trigger immediately

### 3. **Jenkins Initial Setup**
- Jenkins container needs initial admin password
- Access via Route53 record or ALB DNS name
- Install required plugins manually

### 4. **WAF Geo-Restriction**
- Currently uses example Portugal IP ranges
- For production, use AWS WAF Geo Match rules or complete IP range list

### 5. **ECS Task Startup**
- ECS tasks may take 5-10 minutes to start
- EC2 instances need to register with ECS cluster first
- Health checks may fail initially

## 🚀 Deployment Steps

1. **Prepare variables:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review plan:**
   ```bash
   terraform plan
   ```

4. **Deploy:**
   ```bash
   terraform apply
   ```

5. **Validate ACM certificate:**
   - Go to AWS Console → Certificate Manager
   - Create DNS validation records
   - Wait for validation

6. **Subscribe to SNS:**
   - Check email for subscription confirmation
   - Click confirmation link

7. **Configure Jenkins:**
   - Access Jenkins via ALB
   - Get initial admin password from logs
   - Install plugins
   - Configure pipeline

## 📊 Deployment Status

**Code Status:** ✅ READY
**Configuration Status:** ⚠️ REQUIRES USER INPUT
**Infrastructure Status:** ⏳ NOT DEPLOYED

## Next Steps

1. Complete the pre-deployment requirements above
2. Run `terraform plan` to verify configuration
3. Deploy with `terraform apply`
4. Follow post-deployment steps in DEPLOYMENT.md



