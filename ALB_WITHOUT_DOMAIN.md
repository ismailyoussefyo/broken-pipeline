# Using ALB Without a Domain

## ✅ Configuration Complete!

Your Terraform configuration has been updated to work **without a domain**. You can now deploy and access your ALBs directly via their DNS names.

## What Changed

1. **Domain name is now optional** - Set `domain_name = ""` in `terraform.tfvars`
2. **Route53 and ACM are optional** - Only created if domain_name is provided
3. **HTTP listener added** - ALBs will listen on port 80 (HTTP) when no certificate is provided
4. **HTTPS listener optional** - Only created if certificate ARN is provided

## Current Configuration

Your `terraform.tfvars` is already set up:
```hcl
domain_name = ""  # Empty = use ALB DNS names directly
email_address = "ismailmostafa.y@gmail.com"
```

## How to Access Services

After deployment, you'll get ALB DNS names from Terraform outputs:

```bash
terraform output app_alb_dns
terraform output jenkins_alb_dns
```

Then access:
- **Application**: `http://<app-alb-dns-name>`
- **Jenkins**: `http://<jenkins-alb-dns-name>`

## Deployment Steps

1. **Initialize Terraform:**
   ```bash
   cd terraform
   terraform init
   ```

2. **Review plan:**
   ```bash
   terraform plan
   ```

3. **Deploy:**
   ```bash
   terraform apply
   ```

4. **Get ALB DNS names:**
   ```bash
   terraform output app_alb_dns
   terraform output jenkins_alb_dns
   ```

5. **Access services:**
   - Application: `http://<app-alb-dns-name>`
   - Jenkins: `http://<jenkins-alb-dns-name>`

## What Gets Created

**With domain_name = "" (current setup):**
- ✅ 2 VPCs with subnets
- ✅ 2 ECS clusters with EC2 instances
- ✅ 2 ALBs (HTTP on port 80)
- ✅ S3 buckets for logging
- ✅ IAM roles and policies
- ✅ CloudWatch alarms (except Route53 health checks)
- ✅ SNS topic
- ❌ No Route53 hosted zone
- ❌ No ACM certificate
- ❌ No Route53 records
- ❌ No Route53 health checks

## Security Note

- ALBs will use **HTTP (port 80)** instead of HTTPS
- This is fine for testing, but not recommended for production
- Security groups still restrict access appropriately
- Jenkins ALB is still restricted to Portugal IPs via WAF

## Adding a Domain Later

If you want to add a domain later:

1. Update `terraform.tfvars`:
   ```hcl
   domain_name = "your-domain.com"
   ```

2. Run:
   ```bash
   terraform plan
   terraform apply
   ```

3. Update your domain's nameservers to Route53
4. Wait for ACM certificate validation
5. Services will automatically switch to HTTPS

## Ready to Deploy!

Your configuration is ready. Just run:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```



