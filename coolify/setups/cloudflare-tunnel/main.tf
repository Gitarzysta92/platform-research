resource "coolify_project" "networking" {
  name        = var.name
  description = "Cloudflare Tunnel connectivity managed by platform-research Terraform."
}

resource "coolify_service" "cloudflared" {
  name             = "cloudflared"
  project_uuid     = coolify_project.networking.uuid
  server_uuid      = var.coolify_server_uuid
  environment_name = "production"
  instant_deploy   = true

  # Host networking matches Coolify's cloudflared template and makes the
  # loopback proxy reachable without depending on generated Docker networks.
  docker_compose_raw = yamlencode({
    services = {
      cloudflared = {
        image        = var.cloudflared_image
        restart      = "unless-stopped"
        network_mode = "host"
        command      = ["tunnel", "--no-autoupdate", "run"]
        environment = {
          TUNNEL_TOKEN = var.tunnel_token
        }
      }
    }
  })
}
