resource "random_password" "postgres" {
  length  = 40
  special = false
}

resource "random_password" "clickhouse" {
  length  = 40
  special = false
}

resource "random_password" "redis" {
  length  = 40
  special = false
}

resource "random_password" "minio" {
  length  = 40
  special = false
}

resource "random_password" "auth" {
  length  = 64
  special = false
}

resource "random_password" "salt" {
  length  = 40
  special = false
}

resource "random_password" "admin" {
  length  = 40
  special = false
}

resource "random_id" "encryption_key" {
  byte_length = 32
}

resource "coolify_project" "langfuse" {
  name        = var.project_name
  description = "Self-hosted Langfuse stack managed by platform-research Terraform."
}

locals {
  db_url = "postgresql://postgres:${random_password.postgres.result}@postgres:5432/postgres"

  common_env = {
    NEXTAUTH_URL                               = var.langfuse_url
    DATABASE_URL                               = local.db_url
    SALT                                       = random_password.salt.result
    ENCRYPTION_KEY                             = random_id.encryption_key.hex
    TELEMETRY_ENABLED                          = "false"
    CLICKHOUSE_MIGRATION_URL                   = "clickhouse://clickhouse:9000"
    CLICKHOUSE_URL                             = "http://clickhouse:8123"
    CLICKHOUSE_USER                            = "clickhouse"
    CLICKHOUSE_PASSWORD                        = random_password.clickhouse.result
    CLICKHOUSE_CLUSTER_ENABLED                 = "false"
    REDIS_HOST                                 = "redis"
    REDIS_PORT                                 = "6379"
    REDIS_AUTH                                 = random_password.redis.result
    LANGFUSE_S3_EVENT_UPLOAD_BUCKET            = "langfuse"
    LANGFUSE_S3_EVENT_UPLOAD_REGION            = "auto"
    LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID     = "minio"
    LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY = random_password.minio.result
    LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT          = "http://minio:9000"
    LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE  = "true"
    LANGFUSE_S3_MEDIA_UPLOAD_BUCKET            = "langfuse"
    LANGFUSE_S3_MEDIA_UPLOAD_REGION            = "auto"
    LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID     = "minio"
    LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY = random_password.minio.result
    LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE  = "true"
    LANGFUSE_S3_BATCH_EXPORT_ENABLED           = "false"
  }

  dependencies = {
    postgres   = { condition = "service_healthy" }
    clickhouse = { condition = "service_healthy" }
    redis      = { condition = "service_healthy" }
    minio      = { condition = "service_healthy" }
  }

  compose = {
    services = {
      langfuse-web = {
        image      = var.langfuse_image
        restart    = "unless-stopped"
        expose     = ["3000"]
        depends_on = local.dependencies
        environment = merge(local.common_env, {
          HOSTNAME                                   = "0.0.0.0"
          NEXTAUTH_SECRET                            = random_password.auth.result
          LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT          = var.media_url
          LANGFUSE_S3_MEDIA_UPLOAD_INTERNAL_ENDPOINT = "http://minio:9000"
          LANGFUSE_INIT_ORG_ID                       = "platform-research"
          LANGFUSE_INIT_ORG_NAME                     = "Platform Research"
          LANGFUSE_INIT_USER_EMAIL                   = var.initial_user_email
          LANGFUSE_INIT_USER_NAME                    = "Admin"
          LANGFUSE_INIT_USER_PASSWORD                = random_password.admin.result
          AUTH_DISABLE_SIGNUP                        = "true"
        })
      }
      langfuse-worker = {
        image      = var.worker_image
        restart    = "unless-stopped"
        depends_on = local.dependencies
        environment = merge(local.common_env, {
          LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT = "http://minio:9000"
        })
      }
      postgres = {
        image   = "docker.io/postgres:17"
        restart = "unless-stopped"
        environment = {
          POSTGRES_USER     = "postgres"
          POSTGRES_PASSWORD = random_password.postgres.result
          POSTGRES_DB       = "postgres"
        }
        volumes = ["langfuse_postgres_data:/var/lib/postgresql/data"]
        healthcheck = {
          test     = ["CMD-SHELL", "pg_isready -U postgres"]
          interval = "3s"
          timeout  = "3s"
          retries  = 10
        }
      }
      clickhouse = {
        image   = "docker.io/clickhouse/clickhouse-server:25.12"
        restart = "unless-stopped"
        user    = "101:101"
        environment = {
          CLICKHOUSE_DB       = "default"
          CLICKHOUSE_USER     = "clickhouse"
          CLICKHOUSE_PASSWORD = random_password.clickhouse.result
        }
        volumes = ["langfuse_clickhouse_data:/var/lib/clickhouse", "langfuse_clickhouse_logs:/var/log/clickhouse-server"]
        healthcheck = {
          test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:8123/ping || exit 1"]
          interval     = "5s"
          timeout      = "5s"
          retries      = 10
          start_period = "1s"
        }
      }
      redis = {
        image   = "docker.io/redis:7"
        restart = "unless-stopped"
        command = ["redis-server", "--requirepass", random_password.redis.result, "--maxmemory-policy", "noeviction"]
        volumes = ["langfuse_redis_data:/data"]
        healthcheck = {
          test     = ["CMD-SHELL", "redis-cli -a \"$$REDIS_PASSWORD\" ping | grep PONG"]
          interval = "3s"
          timeout  = "10s"
          retries  = 10
        }
        environment = {
          REDIS_PASSWORD = random_password.redis.result
        }
      }
      minio = {
        image      = "cgr.dev/chainguard/minio"
        restart    = "unless-stopped"
        entrypoint = "sh"
        command    = ["-c", "mkdir -p /data/langfuse && minio server --address ':9000' --console-address ':9001' /data"]
        expose     = ["9000"]
        environment = {
          MINIO_ROOT_USER             = "minio"
          MINIO_ROOT_PASSWORD         = random_password.minio.result
          MINIO_API_CORS_ALLOW_ORIGIN = var.langfuse_url
        }
        volumes = ["langfuse_minio_data:/data"]
        healthcheck = {
          test         = ["CMD", "mc", "ready", "local"]
          interval     = "1s"
          timeout      = "5s"
          retries      = 5
          start_period = "1s"
        }
      }
    }
    volumes = {
      langfuse_postgres_data   = {}
      langfuse_clickhouse_data = {}
      langfuse_clickhouse_logs = {}
      langfuse_redis_data      = {}
      langfuse_minio_data      = {}
    }
  }
}

resource "coolify_service" "langfuse" {
  name               = "langfuse"
  description        = "Langfuse web, worker, PostgreSQL, ClickHouse, Redis, and MinIO."
  project_uuid       = coolify_project.langfuse.uuid
  server_uuid        = var.coolify_server_uuid
  environment_name   = "production"
  instant_deploy     = false
  docker_compose_raw = yamlencode(local.compose)

  # Cloudflare terminates TLS; Coolify's origin routes stay HTTP to avoid
  # a proxy redirect loop. Route both hostnames to localhost:80 in the tunnel.
  urls = [
    { name = "langfuse-web", url = replace(var.langfuse_url, "https://", "http://") },
    { name = "minio", url = replace(var.media_url, "https://", "http://") },
  ]
}
