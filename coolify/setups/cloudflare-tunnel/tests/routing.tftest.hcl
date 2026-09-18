mock_provider "cloudflare" {}
mock_provider "coolify" {}

variables {
  coolify_endpoint      = "http://192.0.2.10:8000"
  coolify_server_uuid   = "550e8400-e29b-41d4-a716-446655440000"
  cloudflare_account_id = "0123456789abcdef0123456789abcdef"
  cloudflare_zone_id    = "abcdef0123456789abcdef0123456789"
  base_domain           = "example.com"
}

run "dashboard_and_apps" {
  command = plan

  assert {
    condition     = length(cloudflare_dns_record.coolify) == 2 && cloudflare_dns_record.coolify["dashboard"].name == "coolify.example.com" && cloudflare_dns_record.coolify["wildcard"].proxied
    error_message = "The dashboard and wildcard must receive proxied DNS without taking over the apex."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.coolify.config.ingress[0].hostname == "coolify.example.com" && cloudflare_zero_trust_tunnel_cloudflared_config.coolify.config.ingress[1].hostname == "*.example.com" && cloudflare_zero_trust_tunnel_cloudflared_config.coolify.config.ingress[2].service == "http_status:404"
    error_message = "Route the dashboard before the wildcard, followed by a catch-all 404."
  }

  assert {
    condition     = coolify_service.cloudflared.instant_deploy && cloudflare_zero_trust_tunnel_cloudflared_config.coolify.config.ingress[1].service == "http://127.0.0.1:80"
    error_message = "Start the connector and route applications to the Coolify proxy."
  }
}

run "optional_apex" {
  command = plan
  variables {
    route_apex          = true
    dashboard_subdomain = "platform"
  }

  assert {
    condition     = length(cloudflare_dns_record.coolify) == 3 && cloudflare_dns_record.coolify["apex"].name == "example.com" && output.dashboard_url == "https://platform.example.com"
    error_message = "Optional apex routing and a custom dashboard label must be respected."
  }

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.coolify.config.ingress[1].hostname == "example.com" && cloudflare_zero_trust_tunnel_cloudflared_config.coolify.config.ingress[3].service == "http_status:404"
    error_message = "The apex route must precede the final catch-all."
  }
}
