#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.env"
mkdir -p "$SCRIPT_DIR/certs"

# 1. Generate CA
openssl genrsa -out "$SCRIPT_DIR/certs/ca.key" 4096
openssl req -new -x509 -days 3650 -key "$SCRIPT_DIR/certs/ca.key" \
  -out "$SCRIPT_DIR/certs/ca.crt" \
  -subj "/CN=Home Lab CA"

# 2. Generate server key + CSR
openssl genrsa -out "$SCRIPT_DIR/certs/local.key" 2048
openssl req -new -key "$SCRIPT_DIR/certs/local.key" \
  -out "$SCRIPT_DIR/certs/local.csr" \
  -subj "/CN=*.${TAILSCALE_DOMAIN}"

# 3. Sign with CA (825 day limit for mobile compatibility)
openssl x509 -req -days 825 \
  -in "$SCRIPT_DIR/certs/local.csr" \
  -CA "$SCRIPT_DIR/certs/ca.crt" \
  -CAkey "$SCRIPT_DIR/certs/ca.key" \
  -CAcreateserial \
  -out "$SCRIPT_DIR/certs/local.crt" \
  -extfile <(printf "subjectAltName=DNS:*.${TAILSCALE_DOMAIN},DNS:${TAILSCALE_DOMAIN}")
