mock_provider "coolify" {}

variables {
  coolify_endpoint    = "http://192.0.2.10:8000"
  coolify_server_uuid = "550e8400-e29b-41d4-a716-446655440000"
  tunnel_token        = "test-only-connector-token"
}

run "existing_tunnel_connector" {
  command = plan
  assert {
    condition     = yamldecode(coolify_service.cloudflared.docker_compose_raw).services.cloudflared.environment.TUNNEL_TOKEN == var.tunnel_token
    error_message = "The connector must use the supplied existing tunnel token."
  }
  assert {
    condition     = yamldecode(coolify_service.cloudflared.docker_compose_raw).services.cloudflared.network_mode == "host" && coolify_service.cloudflared.instant_deploy
    error_message = "Start the connector with host networking so it can reach the local proxy."
  }
}

run "reject_empty_token" {
  command = plan
  variables {
    tunnel_token = " "
  }
  expect_failures = [var.tunnel_token]
}
