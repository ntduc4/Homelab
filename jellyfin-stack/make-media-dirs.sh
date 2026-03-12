#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.env"
mkdir -p "${MEDIA_PATH}/"/{tv,movies,downloads/{complete,incomplete}}
