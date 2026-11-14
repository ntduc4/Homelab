# Dev services

Forgejo, Bambuddy, and a Bambu Studio API slicing sidecar. Copy `.env.example` to `.env` and set:

- `TAILSCALE_DOMAIN` / `EXTERNAL_DOMAIN`: private/public routes for Forgejo and Bambuddy.
- `LFS_DATA_PATH`: Forgejo LFS files; its application data and SQLite database remain in `data/`.
- `VIRTUAL_PRINTER_PASV_ADDRESS`: reachable host IP for Bambuddy's virtual printer; `BAMBUDDY_FTP_PASSIVE_RANGE` controls passive FTP ports.
- `BAMBUDDY_WEB_PORT`, `BAMBUDDY_VERSION`, `BAMBUDDY_EXTERNAL_ROOTS`: Bambuddy settings; `SIDECAR_TAG`, `BAMBU_API_PORT`, `MAX_MODEL_UPLOAD_MB`: slicing sidecar settings. `TZ`, `PUID`, and `PGID` configure Bambuddy (Forgejo uses UID/GID 1000).

Bambuddy state lives in `bambuddy/`. Start with `./dcm.sh up devs` from the repo root; its sidecar image requires an x86-64 host.
