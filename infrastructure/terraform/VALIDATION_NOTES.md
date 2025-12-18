# Terraform Validation Notes

## Known Issues and Fixes Required

### Issue 1: S3 Bucket Encryption Configuration

**Problem**: The AWS provider version 5.x changed the resource name from `aws_s3_bucket_encryption` to `aws_s3_bucket_server_side_encryption_configuration` and restructured the block format.

**Current (line 1139, 1664):**

```hcl
resource "aws_s3_bucket_encryption" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.chainfinity.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
```

**Fixed:**

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.chainfinity.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
```

### Issue 2: S3 Lifecycle Configuration

**Problem**: AWS provider requires `filter` or `prefix` in lifecycle rules.

**Fix**: Add `filter {}` to each rule:

```hcl
rule {
  id     = "delete_old_logs"
  status = "Enabled"
  filter {}  # Add this line

  expiration {
    days = 2555
  }
}
```

### Issue 3: Security Group Circular Dependency

**Status**: FIXED via sg_fix.tf

- Created separate aws_security_group_rule resources
- Base security groups defined without inline rules
- Rules reference each other without circular dependency

### Issue 4: CloudWatch Log Group Retention

**Status**: FIXED

- Changed from 2555 days to 3653 days (10 years, closest valid value)
- Valid values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653

### Issue 5: Invalid CIDR Block

**Status**: FIXED

- Changed "10.0.1.0/22" to "10.0.0.0/22"
- CIDR blocks must start at proper boundaries

## Validation Commands

```bash
# Format
terraform fmt -recursive

# Initialize (local backend for testing)
terraform init -backend=false

# Validate (after manual fixes above)
terraform validate

# Plan (requires variables)
export TF_VAR_db_password="test_password_123"
terraform plan -var-file=terraform.tfvars.example
```

## Production Deployment Checklist

- [ ] Fix S3 encryption resource types (2 instances)
- [ ] Add filters to lifecycle rules (2 instances)
- [ ] Update backend configuration with real S3 bucket
- [ ] Set db_password via environment variable or Secrets Manager
- [ ] Replace all ACCOUNT_ID placeholders with actual AWS account ID
- [ ] Replace KMS key ARNs with actual keys
- [ ] Review and adjust network CIDR blocks
- [ ] Configure Route53 hosted zone if manage_dns=true
- [ ] Test with terraform plan before apply
