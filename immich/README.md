# Immich

Photo server, machine learning, PostgreSQL, and Valkey. Copy `.env.example` to `.env` and set:

- `UPLOAD_LOCATION`: photos and generated files, mounted in the server as `/data`.
- `DB_DATA_LOCATION`: PostgreSQL files; use a local filesystem, **not** a network share.
- `DB_PASSWORD`: PostgreSQL secret; `DB_USERNAME` and `DB_DATABASE_NAME`: database identity shared by app and database.
- `IMMICH_VERSION`: image tag; `TAILSCALE_DOMAIN` / `EXTERNAL_DOMAIN`: internal/public routes. `TZ` is optional.

The ML container uses the OpenVINO image and `/dev/dri` on this host. Start with `./dcm.sh up immich` from the repo root; check the upstream Immich Compose release before upgrading it.
