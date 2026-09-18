terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    coolify = {
      source  = "coolify-terraform/coolify"
      version = "0.1.22"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.25.0"
    }
  }
}

# Credentials come from COOLIFY_TOKEN and CLOUDFLARE_API_TOKEN.
provider "coolify" {
  endpoint = var.coolify_endpoint
}

provider "cloudflare" {}
