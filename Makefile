# Load .env file if it exists
-include .env
-include versions.env

# Docker Hub configuration
DOCKER_USERNAME ?= nikgibs ## eventually move to orgs Dockerhub or other registry
IMAGE_NAME ?= $(DOCKER_USERNAME)/infra-management
VERSION ?= v1.0.0

# Default values if not set in .env
TERRAFORM_PATH ?= ./terraform
ANSIBLE_PATH ?= ./ansible
AWS_PROFILE ?= default

.PHONY: help build build-clean run shell clean logs push pull publish

help: ## Show this help
	@echo 'Infrastructure Management Container'
	@echo ''
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Configuration:'
	@echo '  Set DOCKER_USERNAME in .env or override: make push DOCKER_USERNAME=nikgibs'

# For team consumption
pull: ## Pull latest image from Docker Hub
	docker pull $(IMAGE_NAME):$(VERSION)
	docker pull $(IMAGE_NAME):latest

# Local development/testing
build: ## Build the Docker image locally
	docker-compose --env-file versions.env build

build-clean: ## Build the Docker image locally
	docker-compose --env-file versions.env build --no-cache

# For image maintainer
push: ## Push image to Docker Hub (requires Docker Hub login)
	@echo "Pushing $(IMAGE_NAME):$(VERSION) and $(IMAGE_NAME):latest"
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):latest

publish: ## Build and push new version
	make build-clean
	make push
	@echo "Published $(IMAGE_NAME):$(VERSION) to Docker Hub"

# Container operations
up: ## Run container with mounted volumes
	docker-compose --env-file versions.env up -d --wait
	docker-compose logs

shell: ## Execute shell in running container
	docker-compose --env-file versions.env exec infra-management /bin/bash

run: ## Pull latest and start container with shell
	make up
	make shell

down: ## Stop and remove container
	docker-compose down

logs: ## Follow logs for container
	docker-compose logs -f

test: ## Run built-in validation tests
	docker-compose --env-file versions.env exec infra-management /workspace/terraform/test.sh
	docker-compose --env-file versions.env exec infra-management /workspace/ansible/test.sh

status: ## Show container status and tool versions
	docker-compose ps
	docker-compose --env-file versions.env exec infra-management terraform version
	docker-compose --env-file versions.env exec infra-management ansible --version
	docker-compose --env-file versions.env exec infra-management aws --version

clean: ## Remove local Docker images
	docker rmi $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest

# Login helper
login: ## Login to Docker Hub
	docker login