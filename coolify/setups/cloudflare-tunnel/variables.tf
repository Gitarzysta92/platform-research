variable "coolify_endpoint" {
  description = "Existing Coolify base URL reachable independently of this tunnel (no /api/v1 suffix)."
  type        = string
  validation {
    condition     = can(regex("^https?://", var.coolify_endpoint))
    error_message = "Provide an HTTP or HTTPS Coolify base URL."
  }
}

variable "coolify_server_uuid" {
  description = "Existing Linux Coolify server hosting both the dashboard and application proxy."
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account that will own the tunnel."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare DNS zone containing base_domain."
  type        = string
}

variable "base_domain" {
  description = "Domain for application hostnames, e.g. example.com. Must be inside the supplied zone."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", var.base_domain))
    error_message = "Use a lowercase domain without a scheme, wildcard, port, path, or trailing dot."
  }
}

variable "dashboard_subdomain" {
  description = "Single DNS label for the Coolify dashboard under base_domain."
  type        = string
  default     = "coolify"
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.dashboard_subdomain))
    error_message = "Use a single lowercase DNS label."
  }
}

variable "name" {
  description = "Name for the tunnel and the new Coolify networking project."
  type        = string
  default     = "coolify-cloudflare-tunnel"
}

variable "proxy_origin" {
  description = "Coolify proxy URL as reached from the host-networked connector."
  type        = string
  default     = "http://127.0.0.1:80"
  validation {
    condition     = can(regex("^https?://", var.proxy_origin))
    error_message = "The proxy origin must use HTTP or HTTPS."
  }
}

variable "cloudflared_image" {
  description = "Versioned cloudflared image; an immutable digest may also be supplied."
  type        = string
  default     = "cloudflare/cloudflared:2026.9.1"
}

variable "route_apex" {
  description = "Also route base_domain itself to Coolify. Leave false if it hosts another website."
  type        = bool
  default     = false
}
