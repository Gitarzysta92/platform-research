output "cloudflared_service_uuid" {
  value = coolify_service.cloudflared.uuid
}

output "networking_project_uuid" {
  value = coolify_project.networking.uuid
}
