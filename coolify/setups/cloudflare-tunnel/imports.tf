# Imports are reviewed in terraform plan and recorded in state on apply.
import {
  for_each = var.existing_tunnel_id == null ? {} : { existing = var.existing_tunnel_id }
  to       = cloudflare_zero_trust_tunnel_cloudflared.coolify
  id       = "${var.cloudflare_account_id}/${each.value}"
}

import {
  for_each = var.existing_tunnel_id == null ? {} : { existing = var.existing_tunnel_id }
  to       = cloudflare_zero_trust_tunnel_cloudflared_config.coolify
  id       = "${var.cloudflare_account_id}/${each.value}"
}
