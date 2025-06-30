# Load environment files
-include versions.env

# Docker Hub configuration
DOCKER_USERNAME ?= nikgibs ## eventually move to orgs Dockerhub or other registry
IMAGE_NAME ?= $(DOCKER_USERNAME)/infra-management
VERSION ?= v1.0.0

# Development paths (for local testing)
TERRAFORM_PATH ?= ./terraform
ANSIBLE_PATH ?= ./ansible
AWS_PROFILE ?= default

.PHONY: help build build-clean push publish pull test status clean login dev-test prod-publish inspect

help: ## Show container development commands
	@echo 'Infrastructure Management Container Development'
	@echo ''
	@echo 'Development Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E 'build|test|dev' | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Publishing Commands:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E 'push|publish|login' | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Container Operations:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E 'shell|up|down|logs|status|clean' | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Configuration:'
	@echo '  Set DOCKER_USERNAME in .env: echo "DOCKER_USERNAME=nikgibs" > .env'

# Local development builds (single platform, fast)
build: ## Build container locally (current platform)
	docker-compose --env-file versions.env build

build-clean: ## Build container locally, no cache (current platform)
	docker-compose --env-file versions.env build --no-cache

# Multi-platform publishing
push: ## Build and push multi-platform image to Docker Hub
	@echo "Building and pushing multi-platform image..."
	docker buildx build --platform linux/amd64,linux/arm64 \
		--build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
		--build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
		--build-arg AWS_CLI_VERSION=$(AWS_CLI_VERSION) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		--push .

push-clean: ## Build and push multi-platform image, no cache
	@echo "Building and pushing multi-platform image (no cache)..."
	docker buildx build --platform linux/amd64,linux/arm64 --no-cache \
		--build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
		--build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
		--build-arg AWS_CLI_VERSION=$(AWS_CLI_VERSION) \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		--push .

publish: ## Build and push new version (recommended for releases)
	make push-clean
	@echo "✅ Published $(IMAGE_NAME):$(VERSION) and $(IMAGE_NAME):latest to Docker Hub (multi-platform)"

# Pull for testing
pull: ## Pull published image from Docker Hub
	docker pull $(IMAGE_NAME):$(VERSION)
	docker pull $(IMAGE_NAME):latest

# Container operations for development/testing
up: ## Start container for development testing
	docker-compose --env-file versions.env up -d --wait
	docker-compose --env-file versions.env logs

shell: ## Open shell in running container
	docker-compose --env-file versions.env exec infra-management /bin/bash

run: ## Quick start container with shell (for development)
	make up
	make shell

down: ## Stop and remove container
	docker-compose down

logs: ## Follow container logs
	docker-compose --env-file versions.env logs -f

# Testing and validation
test: ## Run built-in validation tests
	@echo "Running container validation tests..."
	docker-compose --env-file versions.env exec infra-management /workspace/terraform/test.sh || echo "Terraform test failed"
	docker-compose --env-file versions.env exec infra-management /workspace/ansible/test.sh || echo "Ansible test failed"

dev-test: ## Complete development test workflow
	@echo "🧪 Running development test workflow..."
	make build-clean
	make up
	@echo "Testing tool versions..."
	docker-compose --env-file versions.env exec infra-management terraform version
	docker-compose --env-file versions.env exec infra-management ansible --version
	docker-compose --env-file versions.env exec infra-management aws --version
	@echo "Running validation tests..."
	make test
	make down
	@echo "✅ Development tests complete"

status: ## Show container status and tool versions
	@echo "=== Container Status ==="
	docker-compose ps
	@echo ""
	@echo "=== Tool Versions ==="
	docker-compose --env-file versions.env exec infra-management terraform version || echo "Container not running"
	docker-compose --env-file versions.env exec infra-management ansible --version || echo "Container not running"
	docker-compose --env-file versions.env exec infra-management aws --version || echo "Container not running"

# Verification and inspection
inspect: ## Inspect published image platforms
	@echo "=== Published Image Platforms ==="
	@docker buildx imagetools inspect $(IMAGE_NAME):$(VERSION) 2>/dev/null || echo "Image not found on Docker Hub"
	@echo ""
	@echo "=== Local Image Info ==="
	@docker image inspect $(IMAGE_NAME):$(VERSION) --format 'Architecture: {{.Architecture}}, OS: {{.Os}}' 2>/dev/null || echo "No local image found"

# Cleanup
clean: ## Remove local Docker images and containers
	docker-compose down
	docker rmi $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest 2>/dev/null || true
	docker system prune -f

# Authentication
login: ## Login to Docker Hub
	docker login

# Production workflow
prod-publish: ## Production publish workflow with validation
	@echo "🚀 Production Release Workflow"
	@echo "Image: $(IMAGE_NAME):$(VERSION)"
	@echo "Tools: Terraform $(TERRAFORM_VERSION), Ansible $(ANSIBLE_VERSION), AWS CLI $(AWS_CLI_VERSION)"
	@echo ""
	@read -p "1. Have you updated CHANGELOG.md? (y/N): " changelog && [ "$$changelog" = "y" ] || (echo "❌ Please update CHANGELOG.md first" && exit 1)
	@read -p "2. Have you tested locally with 'make dev-test'? (y/N): " tested && [ "$$tested" = "y" ] || (echo "❌ Please run 'make dev-test' first" && exit 1)
	@read -p "3. Ready to publish $(IMAGE_NAME):$(VERSION)? (y/N): " confirm && [ "$$confirm" = "y" ] || (echo "❌ Cancelled" && exit 1)
	@echo "Publishing..."
	make login
	make publish
	make inspect
	@echo ""
	@echo "✅ Production release complete!"
	@echo "📋 Next steps:"
	@echo "  1. Update n-gibs/infra-tooling repository if needed"
	@echo "  2. Test with a real project"
	@echo "  3. Announce in #devops Slack channel"

# Version bump helpers
bump-patch: ## Bump patch version (1.0.0 -> 1.0.1)
	@echo "Current version: $(VERSION)"
	@echo "This would bump to next patch version"
	@echo "Update VERSION in Makefile and versions.env manually"

bump-minor: ## Bump minor version (1.0.0 -> 1.1.0)
	@echo "Current version: $(VERSION)"
	@echo "This would bump to next minor version"
	@echo "Update VERSION in Makefile and versions.env manually"

bump-major: ## Bump major version (1.0.0 -> 2.0.0)
	@echo "Current version: $(VERSION)"
	@echo "This would bump to next major version"
	@echo "Update VERSION in Makefile and versions.env manually"