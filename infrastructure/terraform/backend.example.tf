# Terraform Backend Configuration Example
# For local development, comment out the backend block or use local backend
# For production, use S3 backend with your actual values

terraform {
  backend "s3" {
    # Replace with your actual S3 bucket name
    bucket = "YOUR-TERRAFORM-STATE-BUCKET"
    key    = "infrastructure/terraform.tfstate"
    # Replace with your AWS region
    region  = "us-west-2"
    encrypt = true
    # Replace with your actual KMS key ARN
    kms_key_id = "arn:aws:kms:REGION:ACCOUNT_ID:key/KEY_ID"
    # Replace with your DynamoDB table for state locking
    dynamodb_table = "YOUR-TERRAFORM-LOCKS-TABLE"
  }
}

# For local development, use this instead:
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }
