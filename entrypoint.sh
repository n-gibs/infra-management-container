#!/bin/bash
# Infrastructure Container Entrypoint

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display banner with versions
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN} Infrastructure Management Container${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}Tool Versions:${NC}"
echo -e "  Terraform: $(terraform version -json 2>/dev/null | jq -r .terraform_version || terraform --version | head -n1)"
echo -e "  Ansible:   $(ansible --version | grep -oP 'core \K[^\]]+' | cut -d' ' -f2)"
echo -e "  AWS CLI:   $(aws --version | cut -d' ' -f1 | cut -d'/' -f2)"
echo ""
echo -e "${BLUE}Environment:${NC}"
echo -e "  User:         $(whoami)"
echo -e "  Working Dir:  $(pwd)"
echo -e "  AWS Profile:  ${AWS_PROFILE:-default}"
echo ""
echo -e "${GREEN}Ready to work!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

find /workspace -type f -name "*.sh" -exec chmod +x {} \;


exec bash
