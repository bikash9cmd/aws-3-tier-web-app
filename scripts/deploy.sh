#!/bin/bash
# ─────────────────────────────────────────────
# deploy.sh – Full deployment script
# ─────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/environments/prod"
APP_DIR="$SCRIPT_DIR/../app"

echo "🚀 Deploying 3-Tier AWS App..."

# ─── Check prerequisites ──────────────────────
command -v terraform >/dev/null 2>&1 || { echo "❌ terraform not found"; exit 1; }
command -v aws >/dev/null 2>&1       || { echo "❌ aws cli not found"; exit 1; }

# ─── Verify AWS credentials ───────────────────
echo "🔑 Verifying AWS credentials..."
aws sts get-caller-identity --query "Arn" --output text

# ─── Check tfvars exists ──────────────────────
if [ ! -f "$TF_DIR/terraform.tfvars" ]; then
  echo "❌ terraform.tfvars not found!"
  echo "   Copy terraform.tfvars.example to terraform.tfvars and fill in values."
  exit 1
fi

# ─── Terraform deploy ─────────────────────────
cd "$TF_DIR"

echo "📦 Initialising Terraform..."
terraform init

echo "🔍 Validating configuration..."
terraform validate

echo "📋 Planning..."
terraform plan -out=tfplan

echo ""
read -rp "Apply this plan? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo "⚙️  Applying..."
terraform apply tfplan

# ─── Output results ───────────────────────────
echo ""
echo "🎉 Deployment complete!"
echo ""
echo "─── Outputs ─────────────────────────────"
terraform output alb_dns_name
echo ""
echo "Application URL: http://$(terraform output -raw alb_dns_name)"
echo ""
echo "💡 Tip: It may take 2-3 minutes for EC2 instances to pass health checks."
