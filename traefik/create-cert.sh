#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.env"
mkdir -p "$SCRIPT_DIR/certs"

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout "$SCRIPT_DIR/certs/local.key" \
  -out "$SCRIPT_DIR/certs/local.crt" \
  -subj "/CN=*.${PUBLIC_DOMAIN}"
