#!/usr/bin/env bash
# create-dozzle-user.sh
# Usage: ./create-dozzle-user.sh [username] [email] [password] [users-file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

USERNAME=${1:-admin}
EMAIL=${2:-}
PASSWORD=${3:-}
USERS_FILE=${4:-"$SCRIPT_DIR/config/dozzle/users.yml"}

if [[ -z "$EMAIL" ]]; then
  read -rp "Email: " EMAIL
fi

if [[ -z "$PASSWORD" ]]; then
  read -rsp "Password: " PASSWORD
  echo
fi

mkdir -p "$(dirname "$USERS_FILE")"

# Initialise file with root key if it doesn't exist yet
if [[ ! -f "$USERS_FILE" ]]; then
  echo "users:" > "$USERS_FILE"
  echo "Initialised $USERS_FILE"
fi

echo "Generating user '$USERNAME'..."

sudo docker run -it --rm amir20/dozzle generate "$USERNAME" \
  --password "$PASSWORD" \
  --email "$EMAIL" \
  --name "$USERNAME" >> "$USERS_FILE"

echo "Done. Entry appended to $USERS_FILE"
echo "Restart Dozzle for changes to take effect: docker compose restart dozzle"
