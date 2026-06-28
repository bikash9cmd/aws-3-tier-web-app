#!/bin/bash
# ─────────────────────────────────────────────
# destroy.sh – Teardown all infrastructure
# ─────────────────────────────────────────────
set -euo pipefail

TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../terraform/environments/prod"

echo "⚠️  WARNING: This will DESTROY all infrastructure!"
echo ""
read -rp "Type 'destroy' to confirm: " CONFIRM
if [ "$CONFIRM" != "destroy" ]; then
  echo "Aborted."
  exit 0
fi

cd "$TF_DIR"
terraform destroy -auto-approve

echo "✅ Infrastructure destroyed."
