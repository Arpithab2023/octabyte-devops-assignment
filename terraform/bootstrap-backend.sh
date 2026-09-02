#!/usr/bin/env bash
# Run this ONCE, manually, before `terraform init`.
# Creates the S3 bucket + DynamoDB table used for remote state locking.
set -euo pipefail

REGION="us-east-1"
BUCKET="octabyte-tfstate-$(date +%s | tail -c 6)"   # replace with a fixed, globally-unique name
TABLE="octabyte-tf-locks"

aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "Created bucket: $BUCKET"
echo "Update terraform/versions.tf backend block with this bucket name, then run terraform init."
