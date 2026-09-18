variable "coolify_endpoint" {
  description = "Existing Coolify base URL reachable independently of the tunnel, without /api/v1."
  type        = string
  validation {
    condition     = can(regex("^https?://", var.coolify_endpoint))
    error_message = "Provide an HTTP or HTTPS Coolify base URL."
  }
}

variable "coolify_server_uuid" {
  description = "Existing Linux Coolify server hosting the dashboard and application proxy."
  type        = string
}

variable "tunnel_token" {
  description = "Connector token for the existing manually managed Cloudflare Tunnel. Supply using TF_VAR_tunnel_token."
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(trimspace(var.tunnel_token)) > 0
    error_message = "Supply the existing tunnel connector token."
  }
}

variable "name" {
  description = "Name of the new Coolify networking project (not the Cloudflare tunnel name)."
  type        = string
  default     = "coolify-cloudflare-tunnel"
}

variable "cloudflared_image" {
  description = "Versioned cloudflared image, or an immutable image digest."
  type        = string
  default     = "cloudflare/cloudflared:2026.9.1"
}
