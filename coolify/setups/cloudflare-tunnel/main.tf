locals {
  dashboard_hostname = "${var.dashboard_subdomain}.${var.base_domain}"
  # Stable keys keep optional apex routing from renumbering DNS resources.
  hostnames = merge({
    dashboard = local.dashboard_hostname
    wildcard  = "*.${var.base_domain}"
  }, var.route_apex ? { apex = var.base_domain } : {})
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "coolify" {
  account_id = var.cloudflare_account_id
  name       = var.name
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "coolify" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.coolify.id
  config = {
    ingress = concat(
      [{ hostname = local.dashboard_hostname, service = var.proxy_origin }],
      var.route_apex ? [{ hostname = var.base_domain, service = var.proxy_origin }] : [],
      [
        { hostname = "*.${var.base_domain}", service = var.proxy_origin },
        { service = "http_status:404" }
      ]
    )
  }
}

resource "cloudflare_dns_record" "coolify" {
  for_each = local.hostnames

  zone_id = var.cloudflare_zone_id
  name    = each.value
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.coolify.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "coolify" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.coolify.id
}

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
          TUNNEL_TOKEN = data.cloudflare_zero_trust_tunnel_cloudflared_token.coolify.token
        }
      }
    }
  })

  depends_on = [cloudflare_zero_trust_tunnel_cloudflared_config.coolify]
}
