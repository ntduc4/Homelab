# Homelab Stack Setup

This README documents the current repo layout, setup order, required `.env` values, and the host-specific hardcoded values that must be checked before running the stack on a fresh machine.

This version uses the updated domain naming:

- `TAILSCALE_DOMAIN` is the default internal/private domain used by your Traefik routes, Homepage links, and Tailscale-only services.
- `EXTERNAL_DOMAIN` is the public internet domain, only used by services that you intentionally expose externally.
- The old generic domain variable has been removed from this README and from the generated `.env.example` files.

> Commit `.env.example`. Do **not** commit real `.env` files, tunnel tokens, API keys, app passwords, database passwords, or generated config folders containing secrets.

## Stack overview

| Folder | Compose file | Main services | Managed by `dcm.sh` target |
|---|---|---|---|
| `traefik/` | `docker-compose.yml` | Traefik reverse proxy, `proxy` Docker network | `traefik` |
| `cloudflared/` | `docker-compose.yml` | Cloudflare Tunnel | `cloudflared` |
| `immich/` | `docker-compose.yml` | Immich server, Immich ML, Valkey, Postgres | `immich` |
| `infras/` | `docker-compose.yml` | Homepage, Dozzle, File Browser, Uptime Kuma, Scrutiny, Beszel, Beszel Agent | `infra` |
| `jellyfin-stack/` | `qbit.docker-compose.yml` | Gluetun, qBittorrent, qBittorrent port updater | `qbit` |
| `jellyfin-stack/` | `arr.docker-compose.yml` | Prowlarr, FlareSolverr, Radarr, Sonarr, Sonarr Anime, Bazarr | `arr` |
| `jellyfin-stack/` | `jellyfin.docker-compose.yml` | Jellyfin, Seerr | `jellyfin` |
| `kiwix/` | `docker-compose.yml` | Kiwix Serve | `kiwix` |
| `nextcloud/` | `docker-compose.yml` | Nextcloud, MariaDB, Redis, Imaginary, Collabora | `nextcloud` |
| `tools/` | `docker-compose.yml` | Stirling PDF, ConvertX, MicroBin | `tools` |
| `recyclarr/` | `docker-compose.yml` | Recyclarr config sync | not currently in `dcm.sh` |

Important naming detail: the folder is `infras/`, but the `dcm.sh` target is `infra`.

```bash
./dcm.sh up infra      # correct
./dcm.sh up infras     # wrong unless you add an alias in dcm.sh
```

## Domain model

Use only these domain variables:

| Variable | Purpose | Example |
|---|---|---|
| `TAILSCALE_DOMAIN` | Internal/Tailscale domain used for private routes and Homepage links | `ts.example.com` |
| `EXTERNAL_DOMAIN` | Public internet domain used only by intentionally external services | `example.com` |

Current intended routing model:

| Service group | Internal route | External route |
|---|---|---|
| Traefik dashboard | `traefik.${TAILSCALE_DOMAIN}` | none by default |
| Infra apps | `homepage.${TAILSCALE_DOMAIN}`, `dozzle.${TAILSCALE_DOMAIN}`, `kuma.${TAILSCALE_DOMAIN}`, etc. | none by default |
| Jellyfin stack | `jellyfin.${TAILSCALE_DOMAIN}`, `sonarr.${TAILSCALE_DOMAIN}`, `qbit.${TAILSCALE_DOMAIN}`, etc. | none by default |
| Tools | `pdf.${TAILSCALE_DOMAIN}`, `convert.${TAILSCALE_DOMAIN}`, `paste.${TAILSCALE_DOMAIN}` | none by default |
| Kiwix | `kiwix.${TAILSCALE_DOMAIN}` | none by default |
| Immich | `immich.${TAILSCALE_DOMAIN}` | `immich.${EXTERNAL_DOMAIN}` |
| Nextcloud | `nextcloud.${TAILSCALE_DOMAIN}` | `nextcloud.${EXTERNAL_DOMAIN}` |
| Collabora | `collabora.${TAILSCALE_DOMAIN}` | `collabora.${EXTERNAL_DOMAIN}` |
| Forgejo | `git.${TAILSCALE_DOMAIN}` | `git.${EXTERNAL_DOMAIN}` |

## Prerequisites

Install Docker Engine and the Docker Compose plugin on the host.

```bash
docker --version
docker compose version
```

The current `dcm.sh` uses `sudo docker compose`, so either keep using sudo or add your user to the Docker group.

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

Required host devices and paths:

```bash
# VPN tunnel device used by Gluetun
ls -lah /dev/net/tun

# Intel iGPU / VAAPI / OpenVINO devices used by Jellyfin and Immich ML
ls -lah /dev/dri
getent group render
stat -c '%g %n' /dev/dri/renderD128

# Disks currently passed into Scrutiny
ls -lah /dev/sdb /dev/sdc /dev/sdd /dev/sde

# Safer stable disk names for Scrutiny
ls -lah /dev/disk/by-id/
```

## `.env.example` rule

Every folder that has a compose file and requires variables should have a matching `.env.example`.

Use this setup pattern:

```bash
cd <stack-folder>
cp .env.example .env
nano .env
docker compose config
```

For the split `jellyfin-stack` compose files:

```bash
cd jellyfin-stack
cp .env.example .env
docker compose -f qbit.docker-compose.yml config
docker compose -f arr.docker-compose.yml config
docker compose -f jellyfin.docker-compose.yml config
```

Suggested root `.gitignore` safety rules:

```gitignore
**/.env
**/.env.*.local
**/certs/*.key
**/certs/*.pem
**/config/**/secrets*
**/config/**/secret*
**/config/**/tokens*
**/config/**/token*
```

Do **not** blindly ignore every `config/` folder if you intentionally version-control non-secret files like `infras/config/homepage/services.yaml`, `settings.yaml`, or Traefik `tls.yml`.

## `dcm.sh` usage

`dcm.sh` manages these stacks in this order:

```text
traefik → qbit → arr → jellyfin → nextcloud → immich → kiwix → tools → infra → cloudflared
```

That means Traefik starts first so the shared external `proxy` network exists before the other stacks start.

Common commands:

```bash
chmod +x ./dcm.sh

# Start everything
./dcm.sh up

# Stop everything, reverse order
./dcm.sh down

# Restart everything
./dcm.sh restart

# Pull images then restart
./dcm.sh update

# Work on one target
./dcm.sh up traefik
./dcm.sh restart arr
./dcm.sh update jellyfin
./dcm.sh up infra
```

`recyclarr/` is present in the repo, but it is not currently in `STACK_ORDER` or `STACK_DIRS`. To manage it with `dcm.sh`, add something like:

```bash
STACK_ORDER=(traefik qbit arr jellyfin nextcloud immich kiwix tools infra recyclarr cloudflared)

STACK_DIRS=(
  # existing entries...
  [recyclarr]="recyclarr"
)
```

## Manual startup order

Use this if you are not using `dcm.sh`:

```bash
cd traefik && docker compose up -d

cd ../jellyfin-stack && docker compose -f qbit.docker-compose.yml up -d
cd ../jellyfin-stack && docker compose -f arr.docker-compose.yml up -d
cd ../jellyfin-stack && docker compose -f jellyfin.docker-compose.yml up -d

cd ../nextcloud && docker compose up -d
cd ../immich && docker compose up -d
cd ../kiwix && docker compose up -d
cd ../tools && docker compose up -d
cd ../infras && docker compose up -d
cd ../cloudflared && docker compose up -d
```

## Common variables

| Variable | Used by | Meaning | Example |
|---|---|---|---|
| `TAILSCALE_DOMAIN` | Traefik routes, Homepage links, most internal services | Internal/Tailscale domain | `ts.example.com` |
| `EXTERNAL_DOMAIN` | Immich, Nextcloud, Collabora | External public domain | `example.com` |
| `DATA_PATH` | Homepage, File Browser, Kiwix, Nextcloud | General data mount | `/media/huyen/MainDisk/data` |
| `MEDIA_PATH` | qBit, Arr apps, Jellyfin | Shared media root | `/media/huyen/MainDisk/media` |
| `JELLY_DATA_PATH` | Homepage, File Browser | Extra media/data mount | `/media/huyen/MainDisk/jelly-data` |
| `THIRD_DISK_PATH` | Homepage | Extra disk mounted as `/disk3` | `/media/huyen/Disk2` |
| `PUID` / `PGID` | Recommended future change | Host user/group for LinuxServer containers | `1000` |
| `RENDER_GID` | Recommended future change | Host render group for `/dev/dri` | `992` |

## Per-folder `.env.example` templates

### `traefik/.env.example`

```dotenv
TAILSCALE_DOMAIN=ts.example.com
```

Notes:

- `traefik/docker-compose.yml` creates the shared Docker network named `proxy`.
- `traefik/config/tls.yml` and `traefik/certs/` must exist for the dynamic TLS config.
- Ports `80` and `443` must be free on the host.
- The Traefik dashboard is routed through `traefik.${TAILSCALE_DOMAIN}`. Add authentication middleware before exposing it anywhere outside your trusted network.

### `cloudflared/.env.example`

```dotenv
CF_TUNNEL_TOKEN=replace-with-cloudflare-tunnel-token
```

Notes:

- The stack joins the external `proxy` network.
- Never commit the real Cloudflare tunnel token.

### `immich/.env.example`

```dotenv
# Domains
TAILSCALE_DOMAIN=ts.example.com
EXTERNAL_DOMAIN=example.com

# Version
IMMICH_VERSION=release

# Storage
UPLOAD_LOCATION=/media/huyen/MainDisk/immich/upload
DB_DATA_LOCATION=/media/huyen/MainDisk/immich/postgres

# Database
DB_USERNAME=immich
DB_PASSWORD=change-me-long-random-password
DB_DATABASE_NAME=immich
```

Notes:

- The server route accepts both `immich.${TAILSCALE_DOMAIN}` and `immich.${EXTERNAL_DOMAIN}`.
- The machine-learning image currently uses the OpenVINO suffix: `${IMMICH_VERSION:-release}-openvino`.
- Immich ML passes `/dev/dri:/dev/dri` and hardcodes `group_add: "992"`. Verify this is your host render group.
- Immich server transcoding hardware acceleration is commented out. Only enable it after choosing the right `hwaccel.transcoding.yml` service for your hardware.

### `infras/.env.example`

```dotenv
# Domain
TAILSCALE_DOMAIN=ts.example.com

# Storage mounts used by Homepage and File Browser
DATA_PATH=/media/huyen/MainDisk/data
JELLY_DATA_PATH=/media/huyen/MainDisk/jelly-data
THIRD_DISK_PATH=/media/huyen/Disk2

# Scrutiny notifications; leave blank if unused
SCRUTINY_NOTIFY_URLS=

# Homepage widget variables
HOMEPAGE_VAR_JELLYFIN_KEY=replace-with-jellyfin-api-key
HOMEPAGE_VAR_NEXTCLOUD_USERNAME=replace-with-nextcloud-username
HOMEPAGE_VAR_NEXTCLOUD_PASSWORD=replace-with-nextcloud-app-password
HOMEPAGE_VAR_IMMICH_KEY=replace-with-immich-api-key
HOMEPAGE_VAR_JELLYSEERR_KEY=replace-with-seerr-api-key
HOMEPAGE_VAR_SONARR_KEY=replace-with-sonarr-api-key
HOMEPAGE_VAR_SONARR_ANIME_KEY=replace-with-sonarr-anime-api-key
HOMEPAGE_VAR_RADARR_KEY=replace-with-radarr-api-key
HOMEPAGE_VAR_BAZARR_KEY=replace-with-bazarr-api-key
HOMEPAGE_VAR_PROWLARR_KEY=replace-with-prowlarr-api-key
HOMEPAGE_VAR_QBIT_USERNAME=replace-with-qbit-username
HOMEPAGE_VAR_QBIT_PASSWORD=replace-with-qbit-password
HOMEPAGE_VAR_BESZEL_USERNAME=replace-with-beszel-username
HOMEPAGE_VAR_BESZEL_PASSWORD=replace-with-beszel-password
HOMEPAGE_VAR_GLUETUN_KEY=replace-with-gluetun-control-server-api-key

# Recommended: move Beszel agent hardcoded values into env
BESZEL_AGENT_LISTEN=45876
BESZEL_AGENT_KEY=replace-with-key-from-beszel-hub
BESZEL_AGENT_TOKEN=replace-with-token-from-beszel-hub
```

Notes:

- `HOMEPAGE_VAR_DOMAIN` is created inside compose from `TAILSCALE_DOMAIN`.
- Homepage config references Stirling PDF, ConvertX, MicroBin, Jellyfin, Nextcloud, Immich, Seerr, Sonarr, Sonarr Anime, Radarr, Bazarr, Prowlarr, qBittorrent, Uptime Kuma, Scrutiny, Beszel, Dozzle, Traefik, Gluetun, and File Browser.
- Dozzle has shell/actions enabled and mounts the Docker socket. Keep it authenticated.
- Uptime Kuma and Beszel currently use `TZ=UTC`; change to `Asia/Singapore` if you want local timestamps.

### `jellyfin-stack/.env.example`

Used by `qbit.docker-compose.yml`, `arr.docker-compose.yml`, and `jellyfin.docker-compose.yml`.

```dotenv
# Domain and shared media path
TAILSCALE_DOMAIN=ts.example.com
MEDIA_PATH=/media/huyen/MainDisk/media

# Gluetun / Private Internet Access
VPN_USERNAME=replace-with-pia-username
VPN_PASSWORD=replace-with-pia-password
PIA_REGION=Netherlands

# qBittorrent WebUI credentials used by qbittorrent-port-updater
QBITTORRENT_USERNAME=replace-with-qbit-username
QBITTORRENT_PASSWORD=replace-with-qbit-password

# FlareSolverr optional overrides
LOG_LEVEL=info
LOG_FILE=none
LOG_HTML=false
CAPTCHA_SOLVER=none
PORT=8191
```

Notes:

- qBittorrent uses `network_mode: service:gluetun`, so its traffic exits through Gluetun.
- qBittorrent WebUI is exposed through Gluetun on port `8070` and routed as `qbit.${TAILSCALE_DOMAIN}`.
- Gluetun is hardcoded for Private Internet Access over OpenVPN, with port forwarding enabled.
- `qbittorrent-port-updater` reads `/gluetun/forwarded_port` and updates qBittorrent.
- qBittorrent has `mem_limit: 3g` and `memswap_limit: 3g` hardcoded.
- Sonarr Anime currently uses normal LinuxServer Sonarr. A commented alternative exists for the Snaacky anime fork.
- Jellyfin maps `/dev/dri/renderD128` and `/dev/dri/card0`, and uses `group_add: "992"`.
- Seerr currently has `TZ=Asia/Tashkent`; use `Asia/Singapore` if this was accidental.

Recommended internal media roots:

```text
/media/tv
/media/anime
/media/movies
/media/downloads
```

### `nextcloud/.env.example`

```dotenv
# Domains
TAILSCALE_DOMAIN=ts.example.com
EXTERNAL_DOMAIN=example.com

# Storage
DATA_PATH=/media/huyen/MainDisk/nextcloud-data

# Database / cache secrets
NC_MYSQL_ROOT_PASSWORD=change-me-root-password
NC_MYSQL_PASSWORD=change-me-nextcloud-db-password
NC_REDIS_PASSWORD=change-me-redis-password
```

Notes:

- Nextcloud app files live in `./config/nextcloud-main`.
- Nextcloud user data lives at `${DATA_PATH}`.
- Collabora is configured for `nextcloud.${TAILSCALE_DOMAIN}` and `nextcloud.${EXTERNAL_DOMAIN}`.
- `extra_hosts` currently points `nextcloud.${TAILSCALE_DOMAIN}` to `172.19.0.2`; this is host/network specific and can break after Docker network recreation.
- `NC_default_phone_region=SG` is Singapore-specific.
- `NC_maintenance_window_start=22` is UTC.

### `kiwix/.env.example`

```dotenv
TAILSCALE_DOMAIN=ts.example.com
DATA_PATH=/media/huyen/MainDisk/kiwix
```

Notes:

The Kiwix command hardcodes these ZIM filenames, so the files must exist directly under `${DATA_PATH}`:

```text
ifixit_en_all_2025-12.zim
stackoverflow.com_en_all_2023-11.zim
wikipedia_en_all_maxi_2026-02.zim
wikipedia_ja_all_maxi_2025-10.zim
wikipedia_vi_all_maxi_2026-02.zim
wikiversity_en_all_maxi_2026-02.zim
```

Update `command:` whenever you add, remove, or rename ZIM files.

### `tools/.env.example`

```dotenv
TAILSCALE_DOMAIN=ts.example.com

# ConvertX
CONVERTX_JWT_SECRET=replace-with-long-random-secret
MAX_CONVERT_PROCESS=1

# MicroBin auth
MICROBIN_USER=replace-with-username
MICROBIN_PASSWORD=replace-with-password
```

Recommended compose changes:

```yaml
convertx:
  environment:
    - JWT_SECRET=${CONVERTX_JWT_SECRET}
    - MAX_CONVERT_PROCESS=${MAX_CONVERT_PROCESS:-1}

microbin:
  environment:
    MICROBIN_PUBLIC_PATH: "https://paste.${TAILSCALE_DOMAIN}"
```

Expected routes from Homepage:

```text
https://pdf.${TAILSCALE_DOMAIN}
https://convert.${TAILSCALE_DOMAIN}
https://paste.${TAILSCALE_DOMAIN}
```

### `recyclarr/.env.example`

Your shown tree does not include a `recyclarr/.env.example`. If `recyclarr/docker-compose.yml` uses `${...}` variables, add one. Common candidates are API keys and URLs for Sonarr/Radarr.

Example placeholder:

```dotenv
# Only include these if your recyclarr compose/config references env vars.
SONARR_URL=http://sonarr:8989
SONARR_API_KEY=replace-with-sonarr-api-key
SONARR_ANIME_URL=http://sonarr-anime:8989
SONARR_ANIME_API_KEY=replace-with-sonarr-anime-api-key
RADARR_URL=http://radarr:7878
RADARR_API_KEY=replace-with-radarr-api-key
```

## Compose route examples after the domain rename

These are the intended route patterns after the rename. Use `TAILSCALE_DOMAIN` for private/internal services, and use `EXTERNAL_DOMAIN` only on services you intentionally expose externally.

```yaml
# Internal-only examples
- "traefik.http.routers.traefik.rule=Host(`traefik.${TAILSCALE_DOMAIN}`)"
- "traefik.http.routers.homepage.rule=Host(`homepage.${TAILSCALE_DOMAIN}`) || Host(`${TAILSCALE_DOMAIN}`)"
- "traefik.http.routers.qbit.rule=Host(`qbit.${TAILSCALE_DOMAIN}`)"
- "traefik.http.routers.jellyfin.rule=Host(`jellyfin.${TAILSCALE_DOMAIN}`)"
- "traefik.http.routers.kiwix.rule=Host(`kiwix.${TAILSCALE_DOMAIN}`)"
- "traefik.http.routers.microbin.rule=Host(`paste.${TAILSCALE_DOMAIN}`)"

# Internal + external examples
- "traefik.http.routers.immich.rule=Host(`immich.${TAILSCALE_DOMAIN}`) || Host(`immich.${EXTERNAL_DOMAIN}`)"
- "traefik.http.routers.nextcloud.rule=Host(`nextcloud.${TAILSCALE_DOMAIN}`) || Host(`nextcloud.${EXTERNAL_DOMAIN}`)"
- "traefik.http.routers.collabora.rule=Host(`collabora.${TAILSCALE_DOMAIN}`) || Host(`collabora.${EXTERNAL_DOMAIN}`)"
```

Homepage should still use `HOMEPAGE_VAR_DOMAIN`, but compose should derive it from `TAILSCALE_DOMAIN`:

```yaml
environment:
  HOMEPAGE_ALLOWED_HOSTS: "homepage.${TAILSCALE_DOMAIN},${TAILSCALE_DOMAIN}"
  HOMEPAGE_VAR_DOMAIN: "${TAILSCALE_DOMAIN}"
```

## Hardcoded values to fix or verify

### Beszel agent key, token, and disk paths

Current `infras/docker-compose.yml` hardcodes the Beszel agent key and token. Move them into `.env` before committing or sharing the repo.

Recommended compose change:

```yaml
beszel-agent:
  environment:
    LISTEN: ${BESZEL_AGENT_LISTEN:-45876}
    KEY: ${BESZEL_AGENT_KEY}
    TOKEN: ${BESZEL_AGENT_TOKEN}
    HUB_URL: "https://beszel.${TAILSCALE_DOMAIN}"
```

Current host-specific disk mounts:

```yaml
- /media/huyen/MainDisk:/extra-filesystems/MainDisk:ro
- /media/huyen/TestHDD:/extra-filesystems/TestHDD:ro
- /media/huyen/Disk2:/extra-filesystems/Disk2:ro
- /media/huyen/Parity:/extra-filesystems/Parity:ro
```

Verify these paths on every host. If the key/token were ever pushed publicly, rotate them in Beszel.

### ConvertX JWT secret

Move the hardcoded ConvertX `JWT_SECRET` into `tools/.env`:

```dotenv
CONVERTX_JWT_SECRET=replace-with-long-random-secret
```

Use it in compose:

```yaml
- JWT_SECRET=${CONVERTX_JWT_SECRET}
```

### Intel GPU / `/dev/dri` assumptions

Jellyfin currently assumes Intel iGPU devices:

```yaml
devices:
  - /dev/dri/renderD128:/dev/dri/renderD128
  - /dev/dri/card0:/dev/dri/card0
group_add:
  - "992"
user: 1000:1000
```

Immich ML currently assumes OpenVINO/iGPU acceleration:

```yaml
image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-openvino
devices:
  - /dev/dri:/dev/dri
group_add:
  - "992"
```

Before running on another machine:

```bash
id
getent group render
ls -lah /dev/dri
stat -c '%g %n' /dev/dri/renderD128
```

If your render group is not `992`, update the compose or parameterize it:

```dotenv
PUID=1000
PGID=1000
RENDER_GID=992
```

Then use `${PUID}`, `${PGID}`, and `${RENDER_GID}` in compose.

### Scrutiny disk devices

Scrutiny currently passes fixed `/dev/sdX` devices:

```yaml
devices:
  - /dev/sdb:/dev/sdb
  - /dev/sdc:/dev/sdc
  - /dev/sdd:/dev/sdd
  - /dev/sde:/dev/sde
```

`/dev/sdX` can change after reboot or SATA/USB/HBA changes. Prefer stable paths from:

```bash
ls -lah /dev/disk/by-id/
```

### Nextcloud Collabora hardcoded Docker IP

Current compose has:

```yaml
extra_hosts:
  - "nextcloud.${TAILSCALE_DOMAIN}:172.19.0.2"
```

This IP can change if Docker networks are recreated. Verify with:

```bash
docker inspect nextcloud-app | grep -A5 IPAddress
```

If Collabora cannot reach Nextcloud, check this first.

### Timezones

Current hardcoded values:

```text
Uptime Kuma: TZ=UTC
Beszel: TZ=UTC
Seerr: TZ=Asia/Tashkent
Nextcloud maintenance window: 22 UTC
```

For Singapore-local service timestamps, use:

```text
TZ=Asia/Singapore
```

### Security-sensitive defaults

Review before exposing services publicly:

- Traefik dashboard is enabled through `api@internal`.
- Dozzle has shell/actions enabled and mounts `/var/run/docker.sock`.
- File Browser should keep authentication enabled.
- qBittorrent should remain behind Gluetun.
- Cloudflare tunnel tokens and generated app passwords must never be committed.

## First-run checklist

1. Clone/copy the repo to the server.
2. Create `.env` from `.env.example` in every stack folder.
3. Fill domain, storage path, password, token, and API key values.
4. Run `traefik/create-cert.sh` or place your real certificates into `traefik/certs`.
5. Verify `traefik/config/tls.yml` references the correct cert files.
6. Verify `/dev/net/tun` exists for Gluetun.
7. Verify `/dev/dri` and render group for Jellyfin/Immich.
8. Verify Scrutiny disk devices or switch to `/dev/disk/by-id`.
9. Start Traefik first.
10. Start qBit/Gluetun.
11. Start Arr apps.
12. Start Jellyfin and configure libraries.
13. Start Nextcloud and finish first-time setup.
14. Start Immich and finish first-time setup.
15. Start Kiwix after confirming `.zim` files exist.
16. Start `tools/`.
17. Start `infras/`.
18. Start Cloudflared if using Cloudflare Tunnel.
19. Generate API keys/app passwords for Homepage widgets and add them to `infras/.env`.

## App-specific post-setup notes

### qBittorrent + Gluetun

- Open qBittorrent at `https://qbit.${TAILSCALE_DOMAIN}`.
- Set the qBittorrent WebUI username/password to match `QBITTORRENT_USERNAME` and `QBITTORRENT_PASSWORD`.
- Confirm Gluetun writes the forwarded port to `jellyfin-stack/config/gluetun/forwarded_port`.
- Confirm `qbittorrent-port-updater` can log in and update qBittorrent's listening port.

### Prowlarr / Sonarr / Radarr / Bazarr

- Configure indexers in Prowlarr.
- Sync Prowlarr applications to:
  - Sonarr: `http://sonarr:8989`
  - Sonarr Anime: `http://sonarr-anime:8989`
  - Radarr: `http://radarr:7878`
- Keep separate root folders:
  - normal TV: `/media/tv`
  - anime: `/media/anime`
  - movies: `/media/movies`
- Keep anime indexers tagged separately in Prowlarr if using the split normal/anime Sonarr setup.

### Jellyfin

- Open `https://jellyfin.${TAILSCALE_DOMAIN}`.
- Add media libraries from `/media`.
- For Intel hardware transcoding, verify Jellyfin can see `/dev/dri/renderD128`.
- If transcoding fails after a host change, check `/dev/dri`, render group ID, and media permissions first.

### Seerr

- Open `https://seerr.${TAILSCALE_DOMAIN}`.
- Connect it to Jellyfin, Sonarr, Sonarr Anime, and Radarr.
- Change `TZ=Asia/Tashkent` to `TZ=Asia/Singapore` if the current value was accidental.

### Nextcloud

- Open `https://nextcloud.${TAILSCALE_DOMAIN}` or `https://nextcloud.${EXTERNAL_DOMAIN}`.
- Generate an app password for Homepage instead of using your main password.
- If Collabora fails, check `aliasgroup1`, Traefik routing, and the hardcoded `extra_hosts` IP.

### Immich

- Open `https://immich.${TAILSCALE_DOMAIN}` or `https://immich.${EXTERNAL_DOMAIN}`.
- Create an API key for Homepage.
- Confirm `immich_machine_learning` starts with the OpenVINO image and can access `/dev/dri`.

### Homepage

Homepage config uses `{{HOMEPAGE_VAR_*}}` placeholders. Fill the matching values in `infras/.env`.

| Service | Where to get value |
|---|---|
| Jellyfin | Dashboard → API Keys |
| Nextcloud | Personal settings → Security → App password |
| Immich | Account settings → API keys |
| Seerr | Settings → API key |
| Sonarr / Radarr / Bazarr / Prowlarr | Settings → General → API key |
| qBittorrent | WebUI username/password |
| Beszel | Beszel login username/password |
| Gluetun | Control server/API key if enabled |

### Beszel

- Start Beszel Hub first.
- In the Beszel UI, add a system/agent.
- Copy the generated key/token into `infras/.env` after parameterizing the compose file.
- Verify mounted extra filesystems show up individually.
- If Homepage only shows one system, make sure `systemId: Host` matches the actual system ID/name in Beszel.

### Uptime Kuma

Suggested internal monitor URLs:

```text
http://beszel:8090
http://stirling-pdf:8080
http://convertx:<port>
http://microbin:<port>
http://jellyfin:8096
http://sonarr:8989
http://sonarr-anime:8989
http://radarr:7878
http://prowlarr:9696
http://bazarr:6767
http://nextcloud-app:80
http://immich-server:2283
http://kiwix:8080
```

For qBittorrent, because it shares Gluetun's network namespace, monitor:

```text
http://gluetun:8070
```

## Validation commands

Validate every compose file before starting:

```bash
cd traefik && docker compose config
cd ../cloudflared && docker compose config
cd ../immich && docker compose config
cd ../infras && docker compose config
cd ../nextcloud && docker compose config
cd ../kiwix && docker compose config
cd ../tools && docker compose config
```

Validate split compose files:

```bash
cd jellyfin-stack
docker compose -f qbit.docker-compose.yml config
docker compose -f arr.docker-compose.yml config
docker compose -f jellyfin.docker-compose.yml config
```

Check Traefik routing:

```bash
docker logs traefik --tail=100
curl -Ik https://traefik.${TAILSCALE_DOMAIN}
curl -Ik https://jellyfin.${TAILSCALE_DOMAIN}
```

Check Gluetun/qBit:

```bash
docker logs gluetun --tail=100
docker logs qbittorrent-port-updater --tail=100
cat jellyfin-stack/config/gluetun/forwarded_port
```

Check hardware acceleration device mapping:

```bash
docker exec jellyfin ls -lah /dev/dri
docker exec immich_machine_learning ls -lah /dev/dri
```

Check proxy network:

```bash
docker network inspect proxy
```

## Backups before updates

Back up at least these paths before large updates:

```text
traefik/config
traefik/certs
cloudflared/.env
immich/.env
immich database data path
nextcloud/.env
nextcloud/config/mysql
nextcloud/config/nextcloud-main
jellyfin-stack/config/qbittorrent
jellyfin-stack/config/prowlarr
jellyfin-stack/config/radarr
jellyfin-stack/config/sonarr
jellyfin-stack/config/sonarr-anime
jellyfin-stack/config/bazarr
jellyfin-stack/config/jellyfin
jellyfin-stack/config/gluetun
infras/.env
infras/config/homepage
infras/config/kuma
infras/config/beszel
infras/config/beszel_agent_data
infras/config/scrutiny
tools/config/convertx
tools/config/microbin
tools/config/stirling
```

Recommended update flow:

```bash
./dcm.sh update <stack>
# or
./dcm.sh update
```

For Immich, check the current Immich release notes before updating because Immich compose files and required services can change between releases.

## Troubleshooting quick map

| Problem | Check first |
|---|---|
| `network proxy declared as external, but could not be found` | Start `traefik` first or run `docker network create proxy` |
| `./dcm.sh up infras` fails | Use target `infra`, not folder name `infras` |
| Recyclarr does not start with `./dcm.sh up` | Add `recyclarr` to `STACK_ORDER` and `STACK_DIRS` |
| Jellyfin cannot hardware transcode | `/dev/dri`, render group ID, `user: 1000:1000`, media permissions |
| Immich ML fails | OpenVINO image suffix, `/dev/dri`, render group ID |
| qBittorrent has no internet | Gluetun logs, VPN credentials, `/dev/net/tun` |
| qBittorrent port not updating | `forwarded_port` file, qBit username/password, updater logs |
| Nextcloud trusted domain error | `TAILSCALE_DOMAIN`, `EXTERNAL_DOMAIN`, `NEXTCLOUD_TRUSTED_DOMAINS` |
| Collabora cannot connect | `aliasgroup1`, Traefik route, `extra_hosts` hardcoded IP |
| Homepage widget broken | Missing `HOMEPAGE_VAR_*` env, wrong internal URL, API key mismatch |
| Scrutiny missing disks | Wrong `/dev/sdX`; use `/dev/disk/by-id` |
| Beszel only shows one disk/system | Extra filesystem mounts, Beszel `systemId`, agent key/token |

