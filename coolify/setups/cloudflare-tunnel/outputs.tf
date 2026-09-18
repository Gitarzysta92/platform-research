output "dashboard_url" {
  description = "Set this as the existing Coolify instance domain so its proxy routes the dashboard and WebSockets."
  value       = "https://${local.dashboard_hostname}"
}

output "application_domain_pattern" {
  value = "https://*.${var.base_domain}"
}

output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.coolify.id
}

output "cloudflared_service_uuid" {
  value = coolify_service.cloudflared.uuid
}
