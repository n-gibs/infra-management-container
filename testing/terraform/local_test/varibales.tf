# Variable definitions

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "team" {
  description = "Team name"
  type        = string
  default     = "infrastructure"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project    = "InfraContainer"
    ManagedBy  = "Terraform"
    Purpose    = "Demo"
  }
}