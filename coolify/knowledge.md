# Coolify knowledge

## Initial findings

- The [Terraform provider](https://github.com/coolify-terraform/terraform-provider-coolify) uses the provider source address `coolify-terraform/coolify` and configures API access with `endpoint` and `token`.
- Upstream provides [examples](https://github.com/coolify-terraform/terraform-provider-coolify/tree/main/examples) to use as references when declaring the first setup.

These are documentation observations, not locally validated behavior. Recorded on 2026-09-18.

## Decisions

- Keep setup declarations and research notes together in this folder.
- Select and record Coolify and provider versions when implementing the first setup.

## Open questions

- Where will Coolify run, and how will the initial instance be bootstrapped?
- Which applications, databases, and supporting services should the first setup include?
- How should environments, DNS, TLS, credentials, and Terraform state be managed?
- How will backups, recovery, upgrades, and monitoring be validated?

## Experiment log

No experiments yet. For each experiment, record the date, versions, setup, steps, observed result, and supporting references.
