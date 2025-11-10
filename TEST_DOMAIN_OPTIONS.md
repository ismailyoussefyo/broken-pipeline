# Test Domain Options for Deployment

## Option 1: Use AWS Route53 Hosted Zone (Recommended for Testing)

You can create a Route53 hosted zone for any domain name, even if you don't own it. However, for ACM certificate validation, you'll need DNS control.

**Steps:**
1. Use any domain name in `terraform.tfvars` (e.g., `test-broken-pipeline.local` or `broken-pipeline-test.com`)
2. Terraform will create the hosted zone
3. For ACM certificate validation, you'll need to either:
   - Own the domain and update nameservers
   - Use a domain you control

## Option 2: Register a Cheap Domain

**Cheap domain registrars:**
- **Namecheap**: ~$1-5/year for .xyz, .info, .site domains
- **Google Domains**: ~$12/year for .com
- **Cloudflare Registrar**: At-cost pricing (~$8-10/year for .com)
- **Porkbun**: Very cheap domains (~$1-3/year for some TLDs)

**Recommended for testing:**
- `.xyz` domain: ~$1-2/year
- `.site` domain: ~$2-3/year
- `.info` domain: ~$2-3/year

**Steps:**
1. Register a domain (e.g., `broken-pipeline-test.xyz`)
2. Update `domain_name` in `terraform.tfvars`
3. After Route53 hosted zone is created, update your domain's nameservers to Route53 nameservers
4. ACM certificate validation will work automatically

## Option 3: Use a Subdomain of Domain You Own

If you already own a domain:

**Steps:**
1. Use a subdomain like `broken-pipeline.yourdomain.com`
2. Update `domain_name` in `terraform.tfvars`
3. After deployment, update your domain's DNS to point the subdomain to Route53 nameservers
4. Or create CNAME records pointing to Route53

## Option 4: Use AWS Route53 Public Hosted Zone (Free Testing)

You can use Route53's public hosted zone feature:

**Steps:**
1. Use any domain name (e.g., `broken-pipeline-test.local`)
2. Terraform creates the hosted zone
3. For testing without HTTPS, you can skip ACM certificate validation temporarily
4. Access services via ALB DNS names directly (not via Route53 records)

## Option 5: Use a Free Domain Service (Not Recommended)

Services like Freenom (.tk, .ml, .ga) offer free domains but:
- Unreliable for production
- May be blocked by some services
- Not suitable for ACM certificates

## Recommended Approach for This Project

**For quick testing:**
1. Register a cheap `.xyz` domain (~$1-2/year) from Namecheap or Porkbun
2. Use it in `terraform.tfvars`
3. After deployment, update nameservers to Route53

**For development/testing without spending:**
1. Use a subdomain of a domain you already own
2. Or use `broken-pipeline-test.local` and access via ALB DNS names

## Quick Setup with Cheap Domain

1. **Register domain:**
   - Go to Namecheap.com or Porkbun.com
   - Search for a cheap domain (e.g., `broken-pipeline-test.xyz`)
   - Complete registration (~$1-2)

2. **Update terraform.tfvars:**
   ```hcl
   domain_name = "broken-pipeline-test.xyz"
   ```

3. **Deploy infrastructure:**
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

4. **Update nameservers:**
   - After deployment, get Route53 nameservers from AWS Console
   - Update your domain registrar with Route53 nameservers
   - Wait for DNS propagation (5-30 minutes)

5. **ACM Certificate:**
   - Route53 will automatically create validation records
   - Certificate will validate automatically once DNS propagates

## Alternative: Test Without Custom Domain

If you want to test without a domain:

1. Use a placeholder domain in `terraform.tfvars`
2. Access services directly via ALB DNS names from Terraform outputs
3. Skip Route53 records (comment them out temporarily)
4. Use self-signed certificates or skip HTTPS for testing



