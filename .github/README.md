# Terraform GitHub Actions Workflows

🚨 **CRITICAL SECURITY NOTICE** 🚨
**INFRASTRUCTURE CHANGES ARE ONLY ALLOWED ON MAIN BRANCH AFTER CODE REVIEW**

This directory contains GitHub Actions workflows for automated Terraform execution without using Terraform Cloud.

## Workflows

### 1. `terraform.yml` - Main Terraform Workflow (Main Branch Only)
This workflow handles the complete Terraform lifecycle for the main branch:
- **Triggers**: Push to `main` branch and pull requests to main
- **Features**:
  - Format checking
  - Validation
  - Planning
  - **Automatic apply ONLY on main branch pushes**
  - Pull request comments with plan details

### 2. `terraform-plan-only.yml` - Plan Only Workflow (Feature Branches)
This workflow is for feature branches:
- **Triggers**: Push to `feature/**`, `hotfix/**`, `release/**` branches and PRs to main
- **Features**:
  - Format checking
  - Validation
  - **Planning ONLY - NO apply operations**
  - Pull request comments with plan details
  - Clear warnings that changes won't be applied automatically

### 3. `terraform-security.yml` - Security-Focused Workflow
This workflow focuses on security and compliance:
- **Triggers**: Push to `main` branch and pull requests to main
- **Features**:
  - tfsec security scanning with SARIF output
  - Automatic SARIF report upload to GitHub Security tab
  - Error handling for missing SARIF files
  - Plan creation and artifact storage

### 4. `branch-protection.yml` - 🚨 CRITICAL SECURITY WORKFLOW
**PREVENTS UNAUTHORIZED INFRASTRUCTURE CHANGES**
- **Triggers**: Any activity on non-main branches
- **Features**:
  - **BLOCKS** all infrastructure changes outside main branch
  - **PREVENTS** accidental apply/destroy operations  
  - **ENFORCES** mandatory code review process
  - **ALERTS** on security policy violations

## 🔒 SECURITY POLICY

### **CRITICAL: Infrastructure Changes Only on Main Branch**
- ❌ **NEVER** run `terraform apply` on feature branches
- ❌ **NEVER** run `terraform destroy` on feature branches  
- ✅ **ALWAYS** use Pull Requests for code review
- ✅ **ALWAYS** merge to main before infrastructure changes

### **Workflow Security:**
1. **Feature Branch**: Plan only, no infrastructure changes
2. **Pull Request**: Code review and approval required
3. **Main Branch**: Infrastructure changes allowed after review
4. **Protection**: Automatic blocking of unauthorized changes

## Setup Instructions

### 1. GitHub Secrets Configuration
Add the following secrets to your GitHub repository:

#### **Required Secrets:**
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
- `AWS_SESSION_TOKEN`: Your AWS session token (required for temporary credentials)
- `AWS_DEFAULT_REGION`: AWS region (e.g., "us-east-1")

**Important**: Use IAM roles with minimal required permissions for Terraform operations.

**Note**: The `AWS_SESSION_TOKEN` is required when using temporary credentials (like those from AWS STS, IAM roles, or AWS SSO). If you're using permanent access keys, you can leave this secret empty or set it to an empty string.

### 2. Required AWS Permissions
The AWS credentials should have permissions for:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "ec2:*",
                "vpc:*",
                "iam:*",
                "rds:*",
                "elasticache:*",
                "lambda:*",
                "apigateway:*",
                "cloudwatch:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. S3 Backend Configuration
The backend configuration is defined in `backend.tf` and uses the S3 bucket `ordering-system-infra-state` for Terraform state storage. Ensure this bucket exists and is properly configured.

## Workflow Behavior

### On Pull Requests:
1. Security scan runs first
2. Terraform plan is created
3. Plan results are commented on the PR
4. Plan artifact is stored for 1 day

### On Push to Main:
1. Security scan runs
2. Terraform plan is created
3. **Terraform apply runs automatically**

### On Push to Feature Branches:
1. Terraform plan is created
2. **NO apply operations - changes are only planned**
3. Pull request comments show plan with warnings about no automatic apply

### On Pull Requests:
1. Security scan runs (for PRs to main)
2. Terraform plan is created
3. Plan results are commented on the PR
4. **NO apply operations - manual review required**

## Workflow Behavior

| Branch Type | Plan | Apply | Destroy | Security Scan |
|-------------|------|-------|---------|---------------|
| `main` | ✅ | ✅ | ✅ | ✅ |
| `feature/*` | ✅ | ❌ | ❌ | ❌ |
| `hotfix/*` | ✅ | ❌ | ❌ | ❌ |
| `release/*` | ✅ | ❌ | ❌ | ❌ |
| PR to `main` | ✅ | ❌ | ❌ | ✅ |

## Version Requirements

### Terraform Version
- **Required**: `1.12.2` (exact version from working state)
- **Used in workflows**: `1.12.2`

### Provider Versions
- **AWS Provider**: `6.9.0` (exact version from working .terraform.lock.hcl)
- **Source**: `hashicorp/aws`

## Environment Variables & Secrets

### **Secrets Used:**
- `AWS_ACCESS_KEY_ID`: AWS Access Key ID
- `AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key  
- `AWS_SESSION_TOKEN`: AWS Session Token (for temporary credentials)
- `AWS_DEFAULT_REGION`: AWS region (e.g., "us-east-1")

### **Environment Variables:**
- `TF_VERSION`: Terraform version (default: 1.12.2)

## Security Features

1. **tfsec Scanning**: Automatically scans Terraform code for security issues
2. **SARIF Reports**: Security findings are uploaded to GitHub Security tab
3. **Minimal Permissions**: Uses least-privilege AWS credentials
4. **Plan Review**: All changes are planned before applying

## Troubleshooting

### Common Issues:

1. **AWS Credentials Error**:
   - Verify secrets are correctly set in GitHub repository settings
   - Check AWS credentials have sufficient permissions

2. **S3 Backend Error**:
   - Ensure S3 bucket exists and is accessible
   - Verify bucket permissions allow Terraform state operations

3. **Terraform Plan Fails**:
   - Check for syntax errors in Terraform files
   - Verify all required variables are defined

5. **tfsec SARIF Upload Fails**:
   - Error: "Resource not accessible by integration"
   - **SOLUTION**: Workflows now include proper permissions
   - **security-events: write** - Required for SARIF upload to Security tab
   - **pull-requests: write** - Required for PR comments
   - **contents: read** - Required for repository access
   - This is automatically handled by the workflows now

4. **Provider Identity Schema Error**:
   - Error: "failed to decode identity: unsupported attribute 'account_id'"
   - This indicates a provider version compatibility issue
   - **SOLUTION**: Using exact versions from your working terraform.tfstate.backup
   - **Terraform**: `1.12.2` (from terraform_version in state)
   - **AWS Provider**: `6.9.0` (from .terraform.lock.hcl)
   - **Complete cleanup**: `rm -rf .terraform .terraform.lock.hcl ~/.terraform.d/plugin-cache`
   - **Force reconfigure**: `terraform init -upgrade -reconfigure`
   - This error is automatically handled by the workflows now

### Manual Execution:
You can manually trigger workflows from the GitHub Actions tab in your repository.

## Troubleshooting

### AWS Credentials Error: "The security token included in the request is invalid"

This error occurs when AWS credentials are invalid or expired. Here's how to fix it:

#### **1. Check Your Secrets**
- Go to your repository **Settings** → **Secrets and variables** → **Actions**
- Verify these secrets exist and are correct:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_SESSION_TOKEN`
  - `AWS_DEFAULT_REGION`

#### **2. Verify AWS Credentials Locally**
```bash
# Test your credentials locally
aws configure list
aws sts get-caller-identity
```

#### **3. Create New AWS Access Keys**
If your credentials are invalid:
1. Go to AWS Console → **IAM** → **Users** → **Your User**
2. Click **Security credentials** tab
3. Click **Create access key**
4. Choose **Application running outside AWS**
5. Copy the new **Access key ID** and **Secret access key**
6. Update your GitHub secrets with the new values

#### **4. Check IAM Permissions**
Ensure your AWS user has these permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "ec2:*",
                "vpc:*",
                "iam:*",
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

#### **5. Verify S3 Bucket Access**
Ensure your AWS user can access the S3 bucket:
```bash
aws s3 ls s3://ordering-system-infra-state
```

#### **6. Version Information Source**
The versions are taken from your actual working Terraform state:
1. **terraform.tfstate.backup**: Shows `terraform_version: "1.12.2"`
2. **.terraform.lock.hcl**: Shows AWS provider `version = "6.9.0"`
3. **These were working**: No need for alternative versions

#### **7. Manual Local Testing**
Test provider compatibility locally:
```bash
# Clean everything
rm -rf .terraform .terraform.lock.hcl
rm -rf ~/.terraform.d/plugin-cache

# Initialize with specific provider
terraform init -upgrade -reconfigure

# Test provider functionality
terraform providers
aws sts get-caller-identity

# Try a simple plan
terraform plan
```

## Best Practices

1. **Always review plans** before merging to main
2. **Use feature branches** for infrastructure changes
3. **Monitor security scan results** in GitHub Security tab
4. **Keep Terraform version updated** in workflow files (currently using 1.12.2)
5. **Use consistent tagging** for resources
6. **Backup state files** regularly
7. **Only apply changes from main branch** - all other branches are plan-only
8. **Use pull requests** for code review before merging to main

## Local Development

For local development, you can use:
```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

Remember to configure your local AWS credentials using AWS CLI or environment variables. 