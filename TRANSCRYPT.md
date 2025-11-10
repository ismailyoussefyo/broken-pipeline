# Transcrypt Configuration for Sensitive Credentials

## Overview

Transcrypt is used to encrypt sensitive files in the repository while keeping them version-controlled. This allows secure storage of credentials and secrets.

## Installation

```bash
# Install transcrypt
pip install transcrypt

# Or via Homebrew (macOS)
brew install transcrypt
```

## Setup

1. **Initialize transcrypt in the repository:**
   ```bash
   transcrypt
   ```
   This will prompt you to set a password for encryption/decryption.

2. **Add sensitive files to `.gitattributes`:**
   ```bash
   # Example: Encrypt terraform.tfvars if it contains secrets
   echo "terraform/terraform.tfvars filter=crypt diff=crypt merge=crypt" >> .gitattributes
   ```

3. **Encrypt existing sensitive files:**
   ```bash
   transcrypt -c aes-256-cbc -p 'your-password' terraform/terraform.tfvars
   ```

## Usage

- **Encrypt a file:** Files matching patterns in `.gitattributes` are automatically encrypted on commit
- **Decrypt a file:** Files are automatically decrypted on checkout
- **Change password:** `transcrypt -r`
- **List encrypted files:** `transcrypt -l`

## Best Practices

1. **Never commit unencrypted sensitive files**
2. **Use `.gitignore` for truly sensitive files that shouldn't be in git at all**
3. **Share the password securely with team members (use a password manager)**
4. **Use environment variables or AWS Secrets Manager for production secrets**

## Files to Encrypt

The following files may contain sensitive information and should be encrypted:

- `terraform/terraform.tfvars` - Contains AWS credentials, domain names, email addresses
- Any files containing API keys, passwords, or tokens

## Note

For this challenge project, sensitive values are typically passed via environment variables or AWS Secrets Manager in production. Transcrypt is configured for demonstration purposes.



