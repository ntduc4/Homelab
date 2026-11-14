# Traefik

Reverse proxy for the stacks in this repo; creates the shared Docker `proxy` network. Start first with `./dcm.sh up traefik` from the repo root.

Copy `.env.example` to `.env` and set:

- `TAILSCALE_DOMAIN`: private router hostname and wildcard certificate domain.
- `ACME_EMAIL`: Let's Encrypt contact email.
- `CF_DNS_API_TOKEN`: Cloudflare DNS token for the ACME DNS challenge.

`config/` holds dynamic routes/TLS settings; `lets-encrypt/` stores certificate state. The container publishes ports 80 and 443.
