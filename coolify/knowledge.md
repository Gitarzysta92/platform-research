# Coolify knowledge

## Initial findings

- The [Terraform provider](https://github.com/coolify-terraform/terraform-provider-coolify) uses the provider source address `coolify-terraform/coolify` and configures API access with `endpoint` and `token`.
- Upstream provides [examples](https://github.com/coolify-terraform/terraform-provider-coolify/tree/main/examples) to use as references when declaring the first setup.

These are documentation observations, not locally validated behavior. Recorded on 2026-09-18.

## Decisions

- Keep setup declarations and research notes together in this folder.
- Coolify installation is owned by the user's infrastructure script in another repository.
- Expose both the dashboard and hosted HTTP applications through Cloudflare Tunnel.
- [The first setup](setups/cloudflare-tunnel/README.md) pins Coolify provider 0.1.22, Cloudflare provider 5.25.0, and cloudflared 2026.9.1.
- Use a host-networked connector and Coolify's proxy to route hostnames. Preserve independent API access for bootstrap, recovery, and teardown.

## Open questions

- What are the existing instance URL/version, server UUID, Cloudflare account/zone, and base domain?
- Which applications, databases, and supporting services should the first setup include?
- How should environments, DNS, TLS, credentials, and Terraform state be managed?
- How will backups, recovery, upgrades, and monitoring be validated?

## Experiment log

- 2026-09-18: Cloudflare Tunnel configuration validated with Terraform 1.13.5 and the pinned provider schemas. Two mock-provider plan tests passed for dashboard/wildcard routing and optional apex/custom dashboard routing. No live API plan or deployment has been performed.

## Tunnel implementation notes

The provider's `coolify_server_cloudflare_tunnel` toggles a server setting; it does not create Cloudflare DNS or a tunnel. This setup uses the Cloudflare provider for those resources and `coolify_service` for the connector. The server tunnel toggle is not needed for HTTP ingress through the proxy.

Follow the [Coolify tunnel guide](https://coolify.io/docs/integrations/networking/cloudflare/tunnels/all-resource) for origin redirect handling. Configure the dashboard instance domain so Coolify generates its proxy routes. The setup README records prerequisites and validation steps.
