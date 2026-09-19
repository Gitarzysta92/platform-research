mock_provider "coolify" {}

variables {
  coolify_endpoint    = "http://192.0.2.10:8000"
  coolify_server_uuid = "550e8400-e29b-41d4-a716-446655440000"
  langfuse_url        = "https://langfuse.example.com"
  media_url           = "https://langfuse-files.example.com"
  initial_user_email  = "admin@example.com"
}

run "private_dependencies_and_public_routes" {
  command = plan
  assert {
    condition = (
      length(coolify_service.langfuse.urls) == 2 &&
      coolify_service.langfuse.urls[0].name == "langfuse-web" &&
      coolify_service.langfuse.urls[1].name == "minio" &&
      coolify_service.langfuse.urls[0].url == "http://langfuse.example.com" &&
      coolify_service.langfuse.urls[1].url == "http://langfuse-files.example.com"
    )
    error_message = "Expose only the web UI and media API through the HTTP Coolify proxy."
  }
  assert {
    condition = (
      local.compose.services["langfuse-web"].environment.NEXTAUTH_URL == var.langfuse_url &&
      local.compose.services["langfuse-web"].environment.LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT == var.media_url &&
      local.compose.services["langfuse-web"].environment.LANGFUSE_S3_MEDIA_UPLOAD_INTERNAL_ENDPOINT == "http://minio:9000" &&
      local.compose.services["langfuse-web"].environment.LANGFUSE_INIT_ORG_ID == "platform-research" &&
      local.compose.services["langfuse-web"].environment.AUTH_DISABLE_SIGNUP == "true"
    )
    error_message = "Auth initialization and external/internal URLs must match the tunnel routing."
  }
}

run "reject_http_public_url" {
  command = plan
  variables {
    langfuse_url = "http://langfuse.example.com"
  }
  expect_failures = [var.langfuse_url]
}
