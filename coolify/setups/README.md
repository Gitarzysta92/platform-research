# Coolify setups

Place each reproducible environment in its own subfolder here.

- [Cloudflare Tunnel](cloudflare-tunnel/README.md): dashboard and application routing for an existing Coolify installation. Prepared, not live-validated.

Each setup should include:

- Its purpose and validation status.
- Prerequisites and tested Coolify, Terraform, and provider versions.
- Infrastructure declarations with example inputs that contain no secrets.
- Bootstrap, plan, apply, verification, and teardown instructions.
- State storage, backup, and recovery details.

Pin the provider version and commit the Terraform dependency lock file when adding a working Terraform setup.
