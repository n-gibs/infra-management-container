# Local Terraform Configuration for Testing
# This uses local resources that don't require AWS credentials

terraform {
  required_version = ">= 1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Create a local file
resource "local_file" "example" {
  filename = "${path.module}/output/hello.txt"
  content  = "Hello from Terraform!\nCreated at: ${timestamp()}\n"
  
  # Create directory if it doesn't exist
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/output"
  }
}

# Simulate some infrastructure work
resource "null_resource" "example_task" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Simulating infrastructure deployment...'"
  }
  
  provisioner "local-exec" {
    command = "sleep 2"
  }
  
  provisioner "local-exec" {
    command = "echo 'Infrastructure deployment complete!'"
  }
}

# Generate a random ID for demo purposes
resource "random_id" "server" {
  byte_length = 4
}

# Create a JSON file with "infrastructure" data
resource "local_file" "infrastructure_config" {
  filename = "${path.module}/output/infrastructure.json"
  content = jsonencode({
    environment = "demo"
    server_id   = random_id.server.hex
    created_at  = timestamp()
    config = {
      app_name = "demo-app"
      version  = "1.0.0"
      features = ["monitoring", "logging", "alerting"]
    }
  })
}

# Variables
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "infra-demo"
}

# Outputs
output "server_id" {
  value = random_id.server.hex
  description = "Random server ID for demo"
}

output "config_file_path" {
  value = local_file.infrastructure_config.filename
  description = "Path to the generated config file"
}

output "message" {
  value = "Terraform successfully created local demo resources!"
}