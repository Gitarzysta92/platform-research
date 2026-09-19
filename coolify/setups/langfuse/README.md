# Langfuse on existing Coolify

This independent Terraform root provisions a dedicated Coolify project and a six-container Langfuse stack: web, worker, PostgreSQL, ClickHouse, Redis, and MinIO. It follows the [official Langfuse v4 Compose stack](https://github.com/langfuse/langfuse/blob/v4.38.0/docker-compose.yml), adding generated credentials, persistent named volumes, a bootstrap administrator, and Coolify proxy domain mappings. Your infrastructure script remains responsible for installing Coolify. The existing `cloudflare-tunnel` Terraform state is unaffected.

## Configure locally

Requires Terraform >=1.7, provider `coolify-terraform/coolify` 0.1.22, an existing Coolify v4.1+ server, and a Coolify API token with project/service write and `read:sensitive` permissions. Langfuse images use upstream's moving major `:4` tag; review the [Langfuse release notes](https://github.com/langfuse/langfuse/releases) before upgrades. Ensure the deployment server can pull the Docker Hub, Langfuse, and Chainguard images and has sufficient memory and disk for the databases. No Cloudflare credentials are used.

From this directory, create local files:

```sh
(umask 077; cp -n terraform.tfvars.example terraform.tfvars)
(umask 077; cp -n .env.example .env)
chmod 600 terraform.tfvars .env
```

Set `coolify_endpoint` to the independently reachable self-hosted API base (`http://192.168.88.220:8000` on the existing instance), `coolify_server_uuid` to the target server (`u6wd8m12ap9kvmmdze6kt9eg` on the existing instance), `langfuse_url` and `media_url` to distinct public HTTPS hostnames, and `initial_user_email` to the intended admin email. The example uses documentation-only addresses; replace all placeholders. Set `COOLIFY_TOKEN` in the local `.env`, or export it in your shell. These are separate files from the connector's local files; the two Terraform roots have separate states.

The `.env`, `terraform.tfvars`, `*.tfstate*`, and plans are Git-ignored; the `.example` files and provider lock file are committed. Check with `git check-ignore -v .env terraform.tfvars` and never force-add secrets. Terraform generates passwords for PostgreSQL, ClickHouse, Redis, MinIO, the initial admin, and Langfuse auth/encryption. **State and Coolify's service configuration contain these secrets.** Protect and back up the local state, or configure an encrypted, access-controlled remote backend before collaborating or running in CI. Changing or losing state can cause credential rotation and data loss. Preserve the PostgreSQL, ClickHouse, Redis, and MinIO volumes in the same backup and recovery process.

## Route through the existing tunnel

In the existing manually managed Cloudflare Tunnel, add published application routes for both hostnames to `http://localhost:80` on the Coolify host, and make sure their proxied DNS and edge certificate cover them. The default suggested hostnames are `langfuse.threesixty.dev` and `langfuse-files.threesixty.dev` (one level below the domain). Coolify's proxy maps the former to `langfuse-web:3000` and the latter to `minio:9000`. The public URL in Langfuse is HTTPS while the Coolify origin URL is HTTP, avoiding the redirect loop seen earlier with this tunnel. Keep the original Host header through the proxy for S3 presigned URLs. Do not route the MinIO admin console or expose the backing databases.

The media hostname is needed by browsers and SDKs for presigned uploads; event ingestion and server-side reads use the internal `http://minio:9000` endpoint. The MinIO endpoint is publicly reachable for signed requests: consider Cloudflare access/rate limits that do not block signed browser/SDK traffic, and verify cross-origin media uploads from the Langfuse UI. See [Langfuse object storage configuration](https://langfuse.com/self-hosting/deployment/infrastructure/blobstorage).

## Validate and provision

```sh
set -a
. ./.env
set +a
terraform init
terraform fmt -check
terraform validate
terraform test
terraform plan -out=langfuse.tfplan
terraform apply langfuse.tfplan
```

The plan should create one project, one Coolify service and eight random credentials. `instant_deploy` is intentionally false so you can verify the generated Coolify Compose and the Cloudflare routes before starting the service from the Coolify UI. Fetch the initial password locally using `terraform output -raw initial_admin_password` and store it in a password manager; avoid logging it or pasting it in chat. The initial user belongs to the precreated Platform Research organization. Open sign-up is disabled; additional accounts need explicit provisioning. Without SMTP, password reset emails are unavailable.

After starting, check all six containers and their health in Coolify; open the Langfuse URL and sign in; test a trace ingestion and an attached media upload from an external browser or SDK; confirm the two HTTPS routes and their certificates; rerun `terraform plan` for drift. A subsequent Compose update in Terraform may require an explicit Coolify redeploy. This setup is configured but **has not been applied or validated on the live server**. `terraform destroy` removes the managed Coolify service and project; inspect and back up all named volumes before any teardown.

## References

- [Coolify Terraform service resource](https://github.com/coolify-terraform/terraform-provider-coolify/blob/v0.1.22/docs/resources/service.md)
- [Langfuse self-hosting Compose guide](https://langfuse.com/self-hosting/deployment/docker-compose)
- [Langfuse headless initialization](https://langfuse.com/self-hosting/administration/headless-initialization)
- [Langfuse authentication hardening](https://langfuse.com/self-hosting/configuration/hardening)
