#!/bin/bash
set -e  # Exit on any error

echo "🔍 Pre-flight checks..."
terraform --version || { echo "❌ Terraform not found"; exit 1; }
echo "✅ Terraform available"

# Test Terraform
echo "📦 Testing Terraform..."
cd /workspace/terraform/local_test
terraform init
terraform plan
terraform apply -auto-approve
echo "✅ Terraform test complete!"
echo ""

# Show Terraform outputs
echo "📊 Terraform Outputs:"
terraform output
echo ""

echo "📁 Results:"
echo "Terraform created files in: /workspace/terraform/output/"
ls -la /workspace/terraform/output/ 2>/dev/null || true