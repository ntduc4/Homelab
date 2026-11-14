# Cloudflared

Cloudflare Tunnel for the services exposed through the shared `proxy` Docker network. Start Traefik first, then `./dcm.sh up cloudflared` from the repo root.

Copy `.env.example` to `.env`. `CF_TUNNEL_TOKEN` is the tunnel's credential, passed to the container as `TUNNEL_TOKEN`; keep the real token out of git. Configure the tunnel's public hostnames in Cloudflare.
