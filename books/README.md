# Books

LazyLibrarian and Kavita. Copy `.env.example` to `.env` and set `MEDIA_PATH` to the mounted media root (`books/` must exist beneath it) and `TAILSCALE_DOMAIN` for their private routes.

The libraries are mounted at `/media` (Kavita uses `/media/books`); app configuration stays in `config/`. Start with `./dcm.sh up books` from the repo root after the media mount is available.
