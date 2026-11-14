# Tools

Stirling PDF, ConvertX, and MicroBin. Copy `.env.example` to `.env` and set:

- `TAILSCALE_DOMAIN` / `EXTERNAL_DOMAIN`: private routes and MicroBin's public URL.
- `CONVERTX_JWT_SECRET`: persistent ConvertX signing secret; `MAX_CONVERT_PROCESS`: concurrent conversions.
- `MICROBIN_USER` / `MICROBIN_PASSWORD`: MicroBin basic-auth credentials.

Service data lives in `config/`. Start with `./dcm.sh up tools` from the repo root, after Traefik has created the `proxy` network.
