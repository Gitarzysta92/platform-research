terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    coolify = {
      source  = "coolify-terraform/coolify"
      version = "0.1.22"
    }
  }
}

# Authentication to the existing self-hosted instance.
provider "coolify" {
  endpoint = var.coolify_endpoint
  # Token is read from COOLIFY_TOKEN.
}
