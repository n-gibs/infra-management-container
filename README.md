# Infrastructure Management Container

Development and maintenance guide for the Infrastructure Management Container.

## 🎯 Overview

This repository contains the Docker container that provides standardized Terraform, Ansible, and AWS CLI tooling. The container is distributed via Docker Hub at `nikgibs/infra-management` and consumed by teams through the separate [infra-tooling repository](https://github.com/n-gibs/infra-tooling).

**Current Tool Versions:**
- Terraform: 1.12.2
- Ansible: 11.7.0  
- AWS CLI: 2.27.45

## 🏗️ Repository Structure

This repository focuses solely on container development:

```
n-gibs/infra-management-container/
├── Dockerfile                 # Container definition
├── versions.env              # Tool versions
├── entrypoint.sh            # Container startup script
├── Makefile                 # Build and publish commands
├── CHANGELOG.md             # Version history
├── testing/                # Development testing examples
│   ├── terraform/
│   └── ansible/
└── README.md               # This file
```

**User-facing tooling** is maintained in the separate [n-gibs/infra-tooling](https://github.com/n-gibs/infra-tooling) repository.

## 🔧 Development Setup

### Prerequisites
- Docker Hub account with push access to `nikgibs/infra-management`
- GitHub access to `n-gibs/infra-management-container`
- Local Docker and Docker Compose
- Make utility

### Local Environment
```bash
git clone https://github.com/n-gibs/infra-management-container.git
cd infra-management-container

# Set your Docker Hub username
echo "DOCKER_USERNAME=nikgibs" > .env

# Build and test locally
make build
make test
```

## 📦 Version Update Process

### 1. Check for Updates

Monitor for new releases:
- [Terraform Releases](https://github.com/hashicorp/terraform/releases)
- [Ansible Releases](https://github.com/ansible/ansible/releases)  
- [AWS CLI Releases](https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst)

### 2. Update Tool Versions

Edit `versions.env`:
```bash
# versions.env
ANSIBLE_VERSION=11.8.0      # Updated
TERRAFORM_VERSION=1.12.3    # Updated  
AWS_CLI_VERSION=2.27.45     # No change
```

### 3. Test the Update

```bash
# Clean build with new versions
make build-clean

# Verify tools work
make shell
terraform version
ansible --version
aws --version

# Run validation tests
make test
```

### 4. Test with Real Examples

```bash
# Test Terraform example
cd terraform
terraform init
terraform validate
terraform plan

# Test Ansible example
cd ../ansible
ansible-playbook --syntax-check site.yml
ansible-lint .
```

### 5. Update Documentation

Update `CHANGELOG.md`:
```markdown
## [1.1.0] - 2025-07-15

### Updated
- Terraform: 1.12.2 → 1.12.3 (security fixes)
- Ansible: 11.7.0 → 11.8.0 (new features)

### Notes
- No breaking changes
- All existing playbooks compatible
```

### 6. Publish New Version

```bash
# Login to Docker Hub
make login

# Update version tag
export VERSION=v1.1.0

# Build and push
make publish

# Verify published image
docker pull nikgibs/infra-management:latest
docker run --rm nikgibs/infra-management:latest terraform version
```

### 7. Update Git Repository

```bash
# Commit changes
git add versions.env CHANGELOG.md
git commit -m "Bump Terraform to 1.12.3, Ansible to 11.8.0"
git tag v1.1.0
git push origin main --tags
```

### 8. Update Infra-Tooling Repository

After publishing a new container version, update the tooling repository if needed:

```bash
# Clone the tooling repository
git clone https://github.com/n-gibs/infra-tooling.git
cd infra-tooling

# Update docker-compose.yml if using specific version tags
# Update examples if new features require changes
# Update README.md if new capabilities are available

git add .
git commit -m "Update for container v1.1.0"
git push origin main
```

## 🚨 Emergency Updates (Security Patches)

For critical security vulnerabilities:

### 1. Immediate Response
```bash
# Update versions.env with patched versions
# Skip extensive testing for critical patches
make build-clean
make test  # Quick validation only

# Emergency publish
make publish

# Notify team immediately
# Post in #devops: "🚨 Container updated for CVE-XXXX-XXXX"
```

### 2. Team Communication
```
🚨 SECURITY UPDATE: Infrastructure Container v1.1.1

Critical security patch for Terraform CVE-2024-XXXX

ACTION REQUIRED:
Teams using infra-tooling should run:
1. cd infra-tooling && docker-compose pull
2. make status (verify new version)
3. Report any issues in #devops

Timeline: Please update by EOD
```

## 🔄 Regular Maintenance Schedule

### Monthly Review (First Friday)
- Check for new tool releases
- Review security advisories
- Plan version updates

### Quarterly Updates (March, June, September, December)
- Major version updates (if stable)
- Example template improvements
- Documentation updates
- Update infra-tooling repository examples

### Annual Review (January)
- Base image updates (Ubuntu LTS)
- Architecture improvements
- Tool additions/removals

## 🧪 Testing Checklist

Before any update:

### Basic Functionality
- [ ] Container builds successfully
- [ ] All tools accessible and working
- [ ] Version numbers correct
- [ ] Entrypoint script displays versions

### Example Templates
- [ ] Terraform examples validate
- [ ] Ansible examples syntax-check
- [ ] No deprecated syntax warnings

### Integration Testing
- [ ] Test with infra-tooling repository
- [ ] Volume mounts work correctly
- [ ] AWS credentials mount works
- [ ] SSH keys mount works

### Compatibility Testing
- [ ] Test with existing team projects using infra-tooling
- [ ] Verify no breaking changes
- [ ] Check tool compatibility matrix

## 📋 Release Process

### Version Numbering
- **Patch** (v1.0.1): Security fixes, minor tool updates
- **Minor** (v1.1.0): New tool versions, new examples
- **Major** (v2.0.0): Breaking changes, major tool upgrades

### Release Tags
```bash
# Tag format: vMAJOR.MINOR.PATCH
git tag v1.1.0
git push origin v1.1.0

# Docker tags
# nikgibs/infra-management:v1.1.0  (specific version)
# nikgibs/infra-management:latest  (current stable)
```

### Release Notes Template
```markdown
## Infrastructure Container v1.1.0

### 🔧 Tool Updates
- Terraform: 1.12.2 → 1.12.3
- Ansible: 11.7.0 → 11.8.0

### 🚀 New Features
- Added support for new Terraform providers
- Improved error handling in entrypoint

### 🐛 Bug Fixes
- Fixed timezone handling
- Updated example configurations

### 📚 Documentation
- Updated tool compatibility matrix
- Added troubleshooting section

### ⚠️ Breaking Changes
None

### 📦 For Teams Using infra-tooling
```bash
docker-compose pull  # Get latest container
make status          # Verify versions
```
```

## 🔐 Security Considerations

### Image Security
- Use official base images only
- Scan for vulnerabilities before release
- Keep minimal package footprint
- Run as non-root user

### Credential Handling
- Never bake credentials into image
- Use read-only mounts for sensitive files
- Document secure usage patterns

### Supply Chain Security
- Pin exact tool versions
- Verify checksums when possible
- Use official download sources only

## 🚀 Publishing Workflow

### Manual Process
```bash
# 1. Update versions
vim versions.env

# 2. Test thoroughly
make build-clean && make test

# 3. Update docs
vim CHANGELOG.md

# 4. Commit and tag
git add . && git commit -m "Release v1.1.0"
git tag v1.1.0

# 5. Publish to Docker Hub
make login && make publish

# 6. Push to GitHub
git push origin main --tags

# 7. Update infra-tooling repository if needed
```

### Automated CI/CD (Future)
```yaml
# .github/workflows/release.yml
name: Build and Publish
on:
  push:
    tags: ['v*']
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and push to nikgibs/infra-management
        # ... Docker build and push steps
```

## 📞 Team Communication

### Update Notifications
- **Slack #devops**: Announce all updates
- **Wiki**: Maintain version history
- **Email**: Critical security updates only

### Support Process
- **Container Issues**: GitHub Issues at https://github.com/n-gibs/infra-management-container/issues
- **Usage Questions**: GitHub Issues at https://github.com/n-gibs/infra-tooling/issues
- **Urgent**: Page on-call DevOps engineer

## 🔗 Related Repositories

- **This Repository (Container)**: https://github.com/n-gibs/infra-management-container
- **User Tooling**: https://github.com/n-gibs/infra-tooling
- **Docker Hub Image**: https://hub.docker.com/r/nikgibs/infra-management

## 📋 Container Development vs. Usage

| Concern | Repository | Purpose |
|---------|------------|---------|
| **Container Development** | `n-gibs/infra-management-container` | Build, test, and publish the Docker image |
| **Team Usage** | `n-gibs/infra-tooling` | Add containerized tooling to projects via git subtree |

---

**Maintainers:** DevOps Team  
**Last Updated:** 2025-06-29  
**Next Review:** 2025-07-29