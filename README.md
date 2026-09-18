# Platform research

Versioned platform setup declarations and a shared knowledge base for each platform we evaluate.

## Platforms

| Platform | Status | Setup tooling |
| --- | --- | --- |
| [Coolify](coolify/README.md) | Research scaffold | [Terraform provider](https://github.com/coolify-terraform/terraform-provider-coolify) |

## Organization

Each platform has a top-level folder containing:

- `README.md`: overview, status, and source references.
- `setups/`: setup declarations and instructions for reproducing environments.
- `knowledge.md`: findings, decisions, limitations, and open questions.

Keep findings linked to their sources and record the versions and dates used when testing. Distinguish proposed setups from validated ones. Commit reusable configuration and examples; keep credentials, local Terraform state, and machine-specific settings out of Git.
