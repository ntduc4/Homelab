# Nextcloud

Nextcloud with MariaDB, Redis, Imaginary, and Collabora. Copy `.env.example` to `.env` and set:

- `TAILSCALE_DOMAIN` / `EXTERNAL_DOMAIN`: internal/public hostnames used by Traefik, Nextcloud, and Collabora.
- `DATA_PATH`: host directory mounted as Nextcloud's `/var/www/html/data`; its app user (`www-data`, UID 33) must be able to read and write it.
- `NC_MYSQL_ROOT_PASSWORD` / `NC_MYSQL_PASSWORD`: MariaDB credentials; `NC_REDIS_PASSWORD`: Redis credential.

The database (`config/mysql/`) and Nextcloud application files (`config/nextcloud-main/`) stay separate from `DATA_PATH`. Keep the database on local storage, not NFS. Start with `./dcm.sh up nextcloud` from the repo root.
