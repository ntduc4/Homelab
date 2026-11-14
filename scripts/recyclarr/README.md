# Recyclarr

Optional standalone Compose service for synchronizing *Arr configuration using the files in `config/`. This folder has no `.env.example` and is not managed by `dcm.sh`.

`docker-compose.yml` runs as UID/GID 1000 and sets `TZ=America/New_York` directly; edit those values in Compose if your host differs. From this folder, use `docker compose config --quiet` to validate and `docker compose up -d` to start it.
