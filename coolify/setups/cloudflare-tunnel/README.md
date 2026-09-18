# Connect existing Coolify to an existing Cloudflare Tunnel

Terraform deploys a `cloudflared` Compose service and a dedicated networking project on your existing self-hosted Coolify server. Your infrastructure script installs Coolify. You manage the tunnel, routes, and DNS manually in Cloudflare.

No Cloudflare API token, account ID, zone ID, tunnel ID, or domain input is required by Terraform. The existing tunnel connector token identifies and authenticates the tunnel connection. Only the Coolify Terraform provider is used.

## Local configuration

Create local files once, preserving existing values:

```sh
(umask 077; test -e terraform.tfvars || cp terraform.tfvars.example terraform.tfvars)
(umask 077; test -e .env || cp .env.example .env)
chmod 600 terraform.tfvars .env
```

In `terraform.tfvars`, set:

- `coolify_endpoint`: existing Coolify base URL, reachable independently of the tunnel.
- `coolify_server_uuid`: existing Linux server hosting Coolify and its proxy.

In `.env`, set:

- `COOLIFY_TOKEN`: API token from your self-hosted Coolify instance, with project/service management and `read:sensitive` permissions. Enable the Coolify API.
- `TUNNEL_TOKEN`: connector token from the Docker command for your manually created Cloudflare Tunnel.

Keep the `export TF_VAR_tunnel_token="$TUNNEL_TOKEN"` line in `.env`; it passes the connector token to Terraform when sourced. Terraform does not load `.env` automatically.

Optional Terraform settings are `name` (the new Coolify project name) and `cloudflared_image` (default `cloudflare/cloudflared:2026.9.1`). Coolify provider 0.1.22 is pinned and documents Coolify v4.1+ support. Terraform >=1.7 and <2.0 is required.

Both actual local files are Git-ignored. Only placeholder examples are committed. Confirm with:

```sh
git check-ignore -v .env terraform.tfvars
git ls-files -- .env terraform.tfvars
```

The second command must return nothing. Do not force-add local files or copy real values into examples. The sensitive connector token is stored in Terraform state and Coolify's Compose configuration. Local state and `.tfplan` files are ignored; use protected remote state when sharing this setup.

## Manual Cloudflare and Coolify routing

On the existing Cloudflare Tunnel, configure published application routes for:

| Hostname | Origin |
| --- | --- |
| `coolify.example.com` | `http://localhost:80` |
| `*.example.com` | `http://localhost:80` |
| `example.com` (optional) | `http://localhost:80` |

Replace example.com with your domain. Configure matching proxied DNS records targeting `<tunnel-id>.cfargotunnel.com`, with edge certificate coverage for the hostnames. Check existing explicit DNS records, which override a wildcard. Preserve any other routes already on the tunnel.

Run the Coolify proxy on the same server as the connector. Set the Coolify instance domain to `https://coolify.example.com` so it generates dashboard and WebSocket routes; assign domains to hosted HTTP applications as well. Following Coolify's HTTP-origin tunnel guide, disable origin HTTP-to-HTTPS redirects where they cause redirect loops. Alternatively configure a verified HTTPS origin manually in Cloudflare.

The connector uses Linux host networking, matching Coolify's upstream template, so localhost reaches the host proxy. The server needs outbound tunnel connectivity and image-pull access. Domains, certificates, route configuration, authentication policies, and Cloudflare Access remain outside this Terraform setup. The HTTP routes cover the dashboard/API/WebSockets and hosted HTTP applications; SSH and database protocols need separate configuration.

## Plan and deploy

From this directory:

```sh
set -a
. ./.env
set +a
terraform init
terraform validate
terraform plan -out=setup.tfplan
terraform apply setup.tfplan
```

The plan should create only a Coolify project and service. If the connector already exists in Coolify, import that service/project before applying instead of deploying a duplicate. Never apply a plan proposing changes to unrelated resources.

Deployment verified on 2026-09-18: project and connector created, four Cloudflare connections registered, and a subsequent Terraform plan reported no changes. The tunnel routes now target the Coolify proxy on port 80, including the dashboard parent hostname. The dashboard still returns a proxy 404; its Coolify instance-domain routing needs configuration. Verify after applying:

1. The cloudflared service is running and the existing tunnel is Healthy.
2. The dashboard domain supports login, live logs, and the web terminal.
3. A configured application domain works without redirect loops.
4. A subsequent Terraform plan has no unexpected changes.

Offline connector checks: `terraform test` (mock provider, no account mutations).

## Recovery and teardown

Retain the independent Coolify endpoint for recovery, updates, and teardown. A stopped connector can be inspected/redeployed through that endpoint. After image/token changes, verify that the running service was redeployed; `instant_deploy` starts the service on creation, not necessarily on updates.

`terraform destroy` removes only the managed Coolify connector and its dedicated project. Your manually created Cloudflare tunnel, routes, and DNS remain. Keep unrelated workloads out of the networking project. Back up the protected Terraform state.

## Sources

- [Coolify service resource](https://github.com/coolify-terraform/terraform-provider-coolify/blob/v0.1.22/docs/resources/service.md)
- [Coolify cloudflared template](https://github.com/coollabsio/coolify/blob/main/templates/compose/cloudflared.yaml)
- [Coolify tunnel routing guide](https://coolify.io/docs/integrations/networking/cloudflare/tunnels/all-resource)

Sources checked on 2026-09-18. Live routing still requires verification on your instance.
