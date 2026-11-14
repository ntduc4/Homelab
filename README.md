# Homelab

Docker Compose services managed by `./dcm.sh`. Traefik provides the shared `proxy` network and routes internal services through `TAILSCALE_DOMAIN`; services explicitly exposed to the internet also use `EXTERNAL_DOMAIN`. Cloudflared provides the public tunnel.

## Services

| Target | Directory | What it runs |
| --- | --- | --- |
| `traefik` | [traefik/](traefik/README.md) | Reverse proxy, HTTPS, shared `proxy` network |
| `cloudflared` | [cloudflared/](cloudflared/README.md) | Cloudflare Tunnel |
| `arr` | [jellyfin-stack/](jellyfin-stack/README.md) | Prowlarr, FlareSolverr, Radarr, Sonarr (TV and anime), Bazarr |
| `jellyfin` | [jellyfin-stack/](jellyfin-stack/README.md) | Jellyfin and Seerr |
| `qbit` | [jellyfin-stack/](jellyfin-stack/README.md) | Legacy GMKtec Gluetun/qBittorrent stack; qBittorrent now runs separately on the NAS |
| `books` | [books/](books/README.md) | LazyLibrarian and Kavita |
| `nextcloud` | [nextcloud/](nextcloud/README.md) | Nextcloud, MariaDB, Redis, Imaginary, Collabora |
| `immich` | [immich/](immich/README.md) | Photos, machine learning, PostgreSQL, Valkey |
| `devs` | [devs/](devs/README.md) | Forgejo, Bambuddy, slicing sidecar |
| `tools` | [tools/](tools/README.md) | Stirling PDF, ConvertX, MicroBin |
| `kiwix` | [kiwix/](kiwix/README.md) | Offline ZIM library |
| `infra` | [infras/](infras/README.md) | Homepage, File Browser, Dozzle, Uptime Kuma, Beszel hub/agent |
| `ai` | [ai/](ai/README.md) | LiteLLM and Onyx; intended for the separate AI host |

[`scripts/recyclarr/`](scripts/recyclarr/README.md) has its own Compose file and is not a `dcm.sh` target. The target is **`infra`**, not `infras`.

## Run it

1. Install Docker Engine and the Compose plugin. Copy the repo-root `.env.example` and each stack's `.env.example` (if present) to `.env`, then fill in domains, storage paths, credentials, and host-specific devices. Keep real `.env` files and secrets out of git.
2. Ensure required storage is mounted **before** starting containers. Set `NAS_IP`, `NAS_MEDIA_EXPORT`, and `NAS_MEDIA_MOUNT` in the repo-root `.env`; point the relevant stack storage paths at that local mount. `dcm.sh` checks the NFS source for `arr`, `jellyfin`, `books`, and `infra`, plus `nextcloud`, `immich`, `devs`, and `kiwix` after their data paths move to NAS. Make the mount persistent and available before Docker auto-restarts containers; direct `docker compose` commands bypass the check.
3. Start Traefik first, then use the manager from the repo root:

```bash
./dcm.sh up traefik
./dcm.sh up              # all stacks selected by DCM_INCLUDE / DCM_EXCLUDE
./dcm.sh up jellyfin     # one target (ignores the filters)
./dcm.sh restart arr
./dcm.sh update tools    # pull images, then restart
./dcm.sh down            # stop selected stacks in reverse order
```

`dcm.sh` uses `sudo docker compose`. Set `DCM_INCLUDE` or `DCM_EXCLUDE` in the repo-root `.env` to select stacks for all-stack commands; individual targets bypass those filters. Leave `qbit` excluded on the GMKtec while qBittorrent runs on the NAS. `jellyfin-stack/` uses separate `qbit.docker-compose.yml`, `arr.docker-compose.yml`, and `jellyfin.docker-compose.yml` files; `dcm.sh` picks the right one for each target.

For a direct Compose command, run it from the stack directory and validate with `docker compose config --quiet` first (add `-f <file>` in `jellyfin-stack/`). The per-stack `.env.example` files document required variables. Back up service configuration, databases, and user data before changing storage paths or updating images; RAID is not a backup.
