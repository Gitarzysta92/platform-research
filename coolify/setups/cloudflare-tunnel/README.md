# Coolify behind Cloudflare Tunnel

Configure an existing Coolify installation to expose its dashboard and HTTP applications through one Cloudflare Tunnel. Coolify installation remains owned by the infrastructure script in the other repository.

Status: configuration prepared; not deployed against a live installation. Provider versions are pinned in `versions.tf`. The connector image defaults to `cloudflare/cloudflared:2026.9.1`.

Local validation on 2026-09-18: Terraform 1.13.5 schema validation passed, along with both mock-provider routing tests. The provider lock file is included.

## Traffic and ownership

```text
https://coolify.example.com ─┐
https://*.example.com ───────┼─ Cloudflare → tunnel → cloudflared → Coolify proxy :80
https://example.com ────────┘                                  ├─ dashboard / WebSockets
  (optional apex)                                             └─ applications / services
```

Terraform creates the remote tunnel configuration, proxied CNAME records, a dedicated Coolify project, and a running cloudflared Compose service. The connector uses the Linux host network, following Coolify's upstream template. It preserves the incoming hostname so Coolify's proxy selects the destination.

This setup targets one server hosting both the Coolify instance and the application proxy. Additional servers need their own routing arrangement. “Everything” here means the dashboard (including API and WebSockets) and HTTP applications with configured domains; databases and SSH are not published by this HTTP wildcard.

The base domain itself is optional (`route_apex = true`). Existing explicit DNS records take precedence over wildcard DNS; migrate any application records that still point elsewhere. Import existing conflicting dashboard/apex/wildcard records before applying rather than creating duplicates.

## Prerequisites

- Terraform >=1.7 and <2.0.
- An existing Linux Coolify server with its proxy running. The pinned provider documents Coolify v4.1+ support; verify your installed version before applying.
- A Coolify API token with permissions to create projects/services and `read:sensitive` for Compose configuration.
- A reachable Coolify API URL independent of the tunnel being created, such as a private network or SSH-forwarded endpoint. Keep this connection for recovery and destruction too.
- A Cloudflare-managed zone and an API token with account-level Tunnel Write and zone-level DNS Write permissions, scoped to the selected account/zone.
- Outbound connectivity for cloudflared and container image pulls.

The dashboard must already have its instance domain set to `https://coolify.<base_domain>` (or your configured dashboard label) in Coolify Settings. Its generated proxy routes must handle the dashboard and WebSockets. This instance setting is not managed by this Terraform configuration; set it through your bootstrap script or the existing dashboard.

The default tunnel origin is HTTP on host loopback. For application domains, follow Coolify's tunnel guide: use the public HTTPS domain and disable the origin's HTTP-to-HTTPS redirect to avoid redirect loops. The dashboard proxy must likewise accept this HTTP origin traffic. If your existing proxy requires HTTPS, set `proxy_origin` to a reachable HTTPS origin with a trusted certificate; TLS verification stays enabled.

Cloudflare must have an active edge certificate for the chosen hostnames. Prefer `app.example.com` under a zone apex such as `example.com`; deeper names such as `app.platform.example.com` may need additional certificate coverage. A tunnel does not provision that coverage automatically.

## Configure and apply

From this directory:

```sh
# Create local files once; keep existing values if these files already exist.
(umask 077; test -e terraform.tfvars || cp terraform.tfvars.example terraform.tfvars)
(umask 077; test -e .env || cp .env.example .env)
chmod 600 terraform.tfvars .env
# Edit terraform.tfvars with the five required inputs and existing tunnel ID/name.
# Edit .env with the two API tokens. Keep tokens single-quoted.

# Terraform reads terraform.tfvars automatically; load .env into this shell.
set -a
. ./.env
set +a

terraform init
terraform fmt -check
terraform validate
terraform plan -out=setup.tfplan
terraform apply setup.tfplan
```

`terraform.tfvars`, plans, and local state are ignored by Git. Credentials are read by the providers from the environment. The tunnel token is sensitive but still stored in Terraform state and the Compose configuration held by Coolify. Use encrypted, access-controlled remote state for shared use; no backend is imposed before one is selected.

Keep real values only in the ignored `terraform.tfvars` and `.env` files. The committed `terraform.tfvars.example` and `.env.example` contain placeholders only. Both local files use owner-only permissions (`600`). Edit tokens in `.env` rather than pasting token-bearing commands into shell history.

Verify exclusion before committing (these commands print paths, not credentials):

```sh
git check-ignore -v .env terraform.tfvars
git ls-files -- .env terraform.tfvars
```

The first command should show matching ignore rules; the second must print nothing. Normal `git add` and `git push` will not include these untracked, ignored files. Do not force-add them (`git add -f`) or copy secrets into tracked files. Save plans with the ignored `.tfplan` extension; arbitrary filenames are not covered by that rule.

Cloudflare Access is not configured here. The dashboard uses Coolify's existing authentication; application authentication stays with each application. Adding Access later requires deciding who can sign in and how API clients and webhooks authenticate.

## Reuse a manually created tunnel

Set `existing_tunnel_id` to its UUID and `name` to its current name in local `terraform.tfvars`. The tunnel must be remotely managed (`config_src = "cloudflare"`). Terraform will import both the tunnel and its configuration during apply; review the import and proposed changes in the plan first. Setting the ID to `null` selects creation of a new tunnel instead.

The declared ingress rules replace the existing tunnel routes. Preserve any unrelated routes in configuration before applying. Existing DNS records need separate imports using their zone/record IDs; the tunnel import does not import DNS records. Once imported, the tunnel is managed by this state and will be deleted by `terraform destroy`, so review teardown carefully.

In `.env`, `CLOUDFLARE_API_TOKEN` must be a Cloudflare management API token, not the connector token. `TUNNEL_TOKEN` is an optional local place to retain your existing connector token; Terraform does not read it because it retrieves the token using the authenticated Cloudflare API. Never copy either token into an example file.

## Verify

1. Confirm the cloudflared service is running in Coolify and the tunnel is Healthy in Cloudflare.
2. Open `terraform output -raw dashboard_url`; test login, live deployment logs, and the web terminal.
3. Assign an application `https://app.<base_domain>` in Coolify and confirm it responds through the tunnel without a redirect loop.
4. Confirm the application's DNS resolves through Cloudflare, especially if an explicit record existed before the wildcard.
5. Re-run `terraform plan`; investigate unexpected changes before accepting the setup as validated.

Offline routing checks (mock providers, no account mutations):

```sh
terraform test
```

## Updates, recovery, and teardown

Keep the independent API endpoint in `coolify_endpoint` for all lifecycle operations. If the tunnel stops, use that endpoint to inspect/redeploy cloudflared. Changing the connector image or token changes Compose; verify the running service after apply and redeploy it in Coolify if needed. `instant_deploy` guarantees startup on creation, not every subsequent update.

Back up Terraform state and retain the independent access details. To remove this setup, run `terraform plan -destroy` followed by `terraform destroy` through the independent endpoint. This deletes the connector, its dedicated project, tunnel configuration, tunnel, and DNS records. It does not uninstall Coolify or delete applications in other projects. Keep unrelated workloads out of the dedicated networking project.

## Sources

- [Coolify: tunnel all resources](https://coolify.io/docs/integrations/networking/cloudflare/tunnels/all-resource)
- [Coolify: instance settings](https://coolify.io/docs/core/instance-management/instance-settings)
- [Coolify cloudflared Compose template](https://github.com/coollabsio/coolify/blob/main/templates/compose/cloudflared.yaml)
- [Coolify service resource, pinned version](https://github.com/coolify-terraform/terraform-provider-coolify/blob/v0.1.22/docs/resources/service.md)
- [Cloudflare Terraform tunnel guide](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/deployment-guides/terraform/)

Sources checked on 2026-09-18. Live reachability and installed Coolify compatibility still require deployment verification.
