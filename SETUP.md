# Repository Setup Guide

## Pre-Commit Hooks Setup

Pre-commit hooks help maintain code quality and security by running checks before commits.

### Installation

1. **Install pre-commit:**
   ```bash
   pip install pre-commit
   ```

2. **Install the hooks:**
   ```bash
   pre-commit install
   ```

3. **Run hooks manually on all files:**
   ```bash
   pre-commit run --all-files
   ```

### Configured Hooks

The `.pre-commit-config.yaml` includes:

1. **pre-commit/pre-commit-hooks:**
   - Trailing whitespace removal
   - End of file fixer
   - YAML/JSON syntax checking
   - Large file detection
   - Merge conflict detection
   - Private key detection

2. **antonbabenko/pre-commit-terraform:**
   - `terraform_fmt`: Formats Terraform files
   - `terraform_validate`: Validates Terraform syntax
   - `terraform_docs`: Generates documentation
   - `terraform_tflint`: Lints Terraform code
   - `terraform_tfsec`: Security scanning

3. **bridgecrewio/checkov:**
   - Security and compliance scanning for Terraform and Dockerfiles
   - Checks for misconfigurations and security issues

4. **Yelp/detect-secrets:**
   - Detects secrets and credentials in files
   - Uses `.detect-secrets.json` configuration
   - Generates `.secrets.baseline` file

### Initial Setup for detect-secrets

1. **Generate baseline:**
   ```bash
   detect-secrets scan > .secrets.baseline
   ```

2. **Review and commit the baseline:**
   ```bash
   git add .secrets.baseline
   git commit -m "Add secrets baseline"
   ```

3. **Future scans will compare against this baseline**

## Transcrypt Setup (Optional)

For encrypting sensitive files in the repository:

1. **Install transcrypt:**
   ```bash
   pip install transcrypt
   # or
   brew install transcrypt
   ```

2. **Initialize in repository:**
   ```bash
   transcrypt
   ```

3. **Configure files to encrypt in `.gitattributes`:**
   ```bash
   echo "terraform/terraform.tfvars filter=crypt diff=crypt merge=crypt" >> .gitattributes
   ```

See `TRANSCRYPT.md` for detailed instructions.

## Repository Structure

```
.
├── .pre-commit-config.yaml    # Pre-commit hooks configuration
├── .detect-secrets.json       # Detect-secrets configuration
├── .gitattributes             # Git file attributes
├── .gitignore                 # Git ignore patterns
├── Dockerfile                 # Customizes infrastructureascode/hello-world
├── Jenkinsfile                # Jenkins pipeline definition
├── scripts/
│   └── verify_health.sh       # Health check script with flaw
├── terraform/                 # Terraform infrastructure code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── data.tf
│   ├── vpc.tf
│   ├── security.tf
│   ├── s3.tf
│   ├── iam.tf
│   ├── ecr.tf
│   ├── route53.tf
│   ├── sns.tf
│   ├── monitoring.tf
│   ├── ecs.tf
│   └── modules/
│       └── ecs-cluster/
└── README.md
```

## Workflow

1. **Before committing:**
   - Pre-commit hooks run automatically
   - Fix any issues reported
   - Re-commit

2. **Manual checks:**
   ```bash
   # Run all pre-commit hooks
   pre-commit run --all-files
   
   # Run specific hook
   pre-commit run terraform_fmt --all-files
   
   # Check for secrets
   detect-secrets scan
   ```

3. **Terraform validation:**
   ```bash
   cd terraform
   terraform fmt -check
   terraform validate
   terraform plan
   ```

## Troubleshooting

### Pre-commit hooks not running
- Ensure hooks are installed: `pre-commit install`
- Check `.git/hooks/pre-commit` exists

### Terraform hooks failing
- Ensure Terraform is installed and in PATH
- Run `terraform init` in terraform directory
- Check Terraform version compatibility

### Detect-secrets false positives
- Update `.secrets.baseline` with known safe values
- Use inline comments to allowlist: `# pragma: allowlist secret`

### Checkov failures
- Review security findings
- Add skip comments for acceptable risks: `# checkov:skip=CKV_AWS_23:reason`



