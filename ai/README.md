# AI

LiteLLM gateway and Onyx (web/API/workers), with PostgreSQL, Redis, OpenSearch, and model servers. Intended for a separate AI host; run `./dcm.sh up ai` from the repo root.

Copy `.env.example` to `.env` and set:

- `EXTERNAL_DOMAIN`: Onyx public URL; `TAILSCALE_DOMAIN`: private domain in the template; `TZ`: timezone.
- `LITELLM_MASTER_KEY` / `OPENROUTER_API_KEY`: LiteLLM access and upstream provider credentials; `LITELLM_LOG`: gateway logging.
- `ONYX_IMAGE_TAG`, `ONYX_AUTH_TYPE`, `ONYX_USER_AUTH_SECRET`: Onyx images and authentication.
- `ONYX_POSTGRES_*`: database name/user/password; `ONYX_OPENSEARCH_ADMIN_PASSWORD` / `ONYX_OPENSEARCH_JAVA_OPTS`: search credentials and memory; `ONYX_LOG_LEVEL` / `ONYX_DISABLE_TELEMETRY`: app settings.

LiteLLM routing is in `config/litellm/config.yaml`; Onyx state is under `config/`. The web entrypoint is published on host port 3000.
