# Media services

Three independent Compose files, managed from the repo root with `./dcm.sh up arr`, `./dcm.sh up jellyfin`, or `./dcm.sh up qbit`.

Copy `.env.example` to `.env` and set:

- `MEDIA_PATH`: mounted library root for Arr and Jellyfin, exposed inside containers as `/media`. Keep the NAS mount available before starting them.
- `TAILSCALE_DOMAIN`: private Traefik hostnames.
- `QBIT_MEDIA_PATH`: separate host path for the legacy GMKtec qBittorrent stack; it is **not** the Arr/Jellyfin library setting.
- `VPN_USERNAME`, `VPN_PASSWORD`, optional `PIA_REGION`: PIA OpenVPN credentials/region for legacy Gluetun. `QBITTORRENT_USERNAME`/`QBITTORRENT_PASSWORD` let the port-forward updater log into qBittorrent.

`arr.docker-compose.yml` runs Prowlarr, FlareSolverr, Radarr, Sonarr (TV/anime), and Bazarr; FlareSolverr's `LOG_*`, `CAPTCHA_SOLVER`, and `PORT` use Compose defaults unless overridden in `.env`. `jellyfin.docker-compose.yml` runs Jellyfin/Seerr; Jellyfin needs the host `/dev/dri` and render group for hardware transcoding. Application settings live in `config/`.

The GMKtec `qbit` Compose file uses `QBIT_MEDIA_PATH`, `/dev/net/tun`, and Gluetun; qBittorrent currently runs separately on the NAS, so keep this legacy stack stopped. When using Compose directly from this folder, specify the relevant file with `-f`.
