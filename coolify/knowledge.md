# Coolify knowledge

## Initial findings

- The [Terraform provider](https://github.com/coolify-terraform/terraform-provider-coolify) uses the provider source address `coolify-terraform/coolify` and configures API access with `endpoint` and `token`.
- Upstream provides [examples](https://github.com/coolify-terraform/terraform-provider-coolify/tree/main/examples) to use as references when declaring the first setup.

These are documentation observations, not locally validated behavior. Recorded on 2026-09-18.

## Decisions

- Keep setup declarations and research notes together in this folder.
- Coolify installation is owned by the user's infrastructure script in another repository.
- Expose both the dashboard and hosted HTTP applications through Cloudflare Tunnel.
- The existing Cloudflare tunnel, routes, and DNS are managed manually. Terraform manages only the Coolify project and cloudflared connector, using the existing tunnel token.
- [The first setup](setups/cloudflare-tunnel/README.md) pins Coolify provider 0.1.22 and cloudflared 2026.9.1. Cloudflare management credentials and IDs are not required.
- Use a host-networked connector and Coolify's proxy to route hostnames. Preserve independent API access for bootstrap, recovery, and teardown.

## Open questions

- Are the manually configured tunnel routes and DNS ready for the dashboard and applications?
- Which applications, databases, and supporting services should the first setup include?
- How should environments, DNS, TLS, credentials, and Terraform state be managed?
- How will backups, recovery, upgrades, and monitoring be validated?

## Experiment log

- 2026-09-18: Coolify-only connector configuration validated with Terraform 1.13.5 and the pinned provider schema. Two mock-provider tests passed for supplied-token deployment with host networking and rejection of empty tokens. Subsequent live deployment created the project and connector successfully. Logs confirmed four registered Cloudflare connections and a post-apply plan found no drift. The manual tunnel routes were corrected to port 80 and now include the dashboard parent hostname in addition to the wildcard. The public dashboard and direct proxy request both return 404; Coolify instance-domain routing remains to be configured.

## Tunnel implementation notes

The provider's `coolify_server_cloudflare_tunnel` toggles a server setting. This setup uses `coolify_service` to run the connector for the manually created tunnel. The server tunnel toggle is not needed for HTTP ingress through the proxy.

Follow the [Coolify tunnel guide](https://coolify.io/docs/integrations/networking/cloudflare/tunnels/all-resource) for origin redirect handling. Configure the dashboard instance domain so Coolify generates its proxy routes. The setup README records prerequisites and validation steps.
