#!/bin/bash
# ─────────────────────────────────────────────────────────────
# bootstrap-state.sh
# Creates S3 bucket + DynamoDB table for Terraform remote state
# Run ONCE before the first terraform init
# ─────────────────────────────────────────────────────────────

set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="bikash-terraform-state-${ACCOUNT_ID}"
DYNAMO_TABLE="terraform-state-lock"

echo "🔧 Setting up Terraform remote state..."
echo "  Account: $ACCOUNT_ID"
echo "  Region:  $REGION"
echo "  Bucket:  $BUCKET_NAME"
echo "  Table:   $DYNAMO_TABLE"

# ─── Create S3 bucket ────────────────────────
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "✅ S3 bucket already exists: $BUCKET_NAME"
else
  echo "🪣 Creating S3 bucket..."
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi

# ─── Enable versioning ───────────────────────
echo "📦 Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# ─── Enable encryption ───────────────────────
echo "🔒 Enabling server-side encryption..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# ─── Block public access ─────────────────────
echo "🛡️  Blocking public access..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# ─── Create DynamoDB table ───────────────────
if aws dynamodb describe-table --table-name "$DYNAMO_TABLE" --region "$REGION" 2>/dev/null; then
  echo "✅ DynamoDB table already exists: $DYNAMO_TABLE"
else
  echo "🗄️  Creating DynamoDB lock table..."
  aws dynamodb create-table \
    --table-name "$DYNAMO_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  aws dynamodb wait table-exists --table-name "$DYNAMO_TABLE" --region "$REGION"
fi

echo ""
echo "✅ Remote state backend ready!"
echo ""
echo "Now update terraform/environments/prod/backend.tf:"
echo "  bucket = \"$BUCKET_NAME\""
echo ""
echo "Then run: cd terraform/environments/prod && terraform init"
