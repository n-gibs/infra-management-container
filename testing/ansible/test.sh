#!/bin/bash
set -e  # Exit on any error

echo "🔍 Pre-flight checks..."
ansible --version || { echo "❌ Ansible not found"; exit 1; }
echo "✅ Ansible available"

# Test Ansible  
echo "📦 Testing Ansible..."
cd /workspace/ansible/local_test
ansible-playbook -i inventory.ini playbook.yml
echo "✅ Ansible test complete!"
echo ""

# Show results
echo "📁 Results:"
echo "Ansible created files in: /tmp/ansible-demo/"
ls -la /tmp/ansible-demo/ 2>/dev/null || true