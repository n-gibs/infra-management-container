# Changelog

All notable changes to the Infrastructure Management Container will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-06-29

### Added
- **Infrastructure Container**: Pre-built Docker container with standardized DevOps tooling
  - Terraform 1.12.2 for Infrastructure as Code
  - Ansible 11.7.0 for Configuration Management  
  - AWS CLI 2.27.45 for AWS resource management
  - Ubuntu 24.04 LTS base image
- **Multi-stage Docker build** for optimized image size and security
- **Container management tools**
  - Makefile with essential container commands
  - Docker Hub publishing workflow
  - Multi-platform support (linux/amd64, linux/arm64)
- **Security features**
  - Non-root user execution (infra:infra)
  - Read-only credential mounts
  - Isolated environment with minimal attack surface
- **Documentation**
  - Comprehensive usage guide for project integration
  - Contributing guide for container maintenance
  - Example project structures and configurations
- **Example templates**
  - Terraform project structure with environments
  - Ansible playbook structure with inventory management
  - Combined infrastructure automation examples

### Technical Details
- **Image**: `nikgibs/infra-management:latest` published to Docker Hub
- **Platforms**: linux/amd64, linux/arm64
- **Base**: Ubuntu 24.04 LTS
- **User**: Non-root (infra:infra) for security
- **Workdir**: `/workspace` with mounted project directories
