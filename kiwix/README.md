# Kiwix

Serves offline ZIM files. Copy `.env.example` to `.env`: `DATA_PATH` is the folder containing the ZIM files mounted at `/data`, and `TAILSCALE_DOMAIN` sets the private hostname.

The filenames served are listed in `docker-compose.yml` under `command`; update that list when the ZIM files change. Start with `./dcm.sh up kiwix` from the repo root.
