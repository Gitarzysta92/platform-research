terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    coolify = {
      source  = "coolify-terraform/coolify"
      version = "0.1.22"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "coolify" {
  endpoint = var.coolify_endpoint
  # Authentication is supplied by COOLIFY_TOKEN.
}
