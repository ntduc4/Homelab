# Traefik

Reverse proxy for the stacks in this repo; creates the shared Docker `proxy` network. Start first with `./dcm.sh up traefik` from the repo root.

Copy `.env.example` to `.env` and set:

- `TAILSCALE_DOMAIN`: private router hostname and wildcard certificate domain.
- `ACME_EMAIL`: Let's Encrypt contact email.
- `CF_DNS_API_TOKEN`: Cloudflare DNS token for the ACME DNS challenge.
- `NAS_IP`: NAS address used by the file-provider route for its qBittorrent WebUI on port 8070.

`config/` holds dynamic routes/TLS settings, including the `qbit` reverse proxy to the NAS; `lets-encrypt/` stores certificate state. The container publishes ports 80 and 443.
