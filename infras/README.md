# Infrastructure dashboard

Homepage, File Browser, Dozzle, Uptime Kuma, and Beszel hub/agent. Run `./dcm.sh up infra` from the repo root (`infra`, not `infras`).

Copy `.env.example` to `.env` and set:

- `TAILSCALE_DOMAIN`: private routes. `HOMEPAGE_VAR_*`: API keys/login details for Homepage widgets.
- `DATA_PATH`, `JELLY_DATA_PATH`, `THIRD_DISK_PATH`: host paths shown by Homepage; File Browser reads the first two. Mount NAS paths before starting the stack.
- `SCRUTINY_NOTIFY_URLS`: notification endpoint if you enable the currently commented-out Scrutiny service.

Application state is in `config/`. Dozzle and Homepage use the Docker socket; Beszel Agent uses host networking and has its hub key/token in `docker-compose.yml`.
