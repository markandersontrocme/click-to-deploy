resource "cloudflare_tunnel" "this" {
  account_id = var.account_id
  name       = var.name
  secret     = var.tunnel_secret
}

resource "cloudflare_record" "this" {
  zone_id = var.zone_id
  name    = var.name
  value   = "${cloudflare_tunnel.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "helm_release" "cloudflared" {
  name             = "cloudflared"
  namespace        = "networking"
  create_namespace = true

  repository = "https://charts.kubito.dev"
  chart      = "cloudflared"
  version    = "1.0.2"

  values = [templatefile("${path.module}/values.template.yaml", {
    ACCOUNT_TAG   = var.account_id,
    TUNNEL_ID     = cloudflare_tunnel.this.id,
    TUNNEL_NAME   = cloudflare_tunnel.this.name,
    TUNNEL_SECRET = var.tunnel_secret,
    HOSTNAME      = cloudflare_record.this.hostname
  })]
}

resource "cloudflare_access_application" "this" {
  zone_id          = var.zone_id
  name             = var.name
  domain           = cloudflare_record.this.hostname
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_access_policy" "this" {
  application_id = cloudflare_access_application.this.id
  zone_id        = var.zone_id
  name           = var.name
  precedence     = "1"
  decision       = "allow"

  include {
    email = var.allowed_emails
  }
}
