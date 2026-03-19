#!/usr/bin/env bash
# dcm.sh — Docker Compose Manager
# Usage: dcm.sh <up|down> [stack_name]

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
# Base directory: defaults to the directory containing this script
BASE_DIR="${DCM_BASE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Stack order: traefik first up, last down
# To add a new stack: append to STACK_ORDER and add an entry in STACK_DIRS (and optionally STACK_FILES)
STACK_ORDER=(traefik arr jellyfin nextcloud immich infra)

declare -A STACK_DIRS=(
    [traefik]="traefik"
    [nextcloud]="nextcloud"
    [immich]="immich"
    [infra]="infras"
    [arr]="jellyfin-stack"
    [jellyfin]="jellyfin-stack"
)

# Optional: override compose files per stack (space-separated)
# If not defined here, defaults to standard "docker compose" with no -f flag
declare -A STACK_FILES=(
    [arr]="arr.docker-compose.yml"
    [jellyfin]="jellyfin.docker-compose.yml"
)
# ──────────────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

usage() {
    echo -e "${BOLD}Usage:${RESET} $(basename "$0") <up|down> [stack]"
    echo
    echo -e "${BOLD}Commands:${RESET}"
    echo -e "  up    Start all stacks (or a specific one)"
    echo -e "  down  Stop all stacks (or a specific one)"
    echo
    echo -e "${BOLD}Available stacks:${RESET}"
    for key in "${!STACK_DIRS[@]}"; do
        local files="${STACK_FILES[$key]:-default}"
        printf "  ${CYAN}%-12s${RESET} →  %s  (%s)\n" "$key" "${STACK_DIRS[$key]}" "$files"
    done | sort
    echo
    echo -e "${BOLD}Startup order:${RESET}  ${STACK_ORDER[*]}"
    echo -e "${BOLD}Shutdown order:${RESET} $(printf '%s\n' "${STACK_ORDER[@]}" | tac | tr '\n' ' ')"
    echo
    echo -e "${BOLD}Examples:${RESET}"
    echo -e "  $(basename "$0") up"
    echo -e "  $(basename "$0") down jellyfin"
    echo -e "  $(basename "$0") up nextcloud"
    exit 1
}

stack_up() {
    local name="$1"
    local dir="$BASE_DIR/${STACK_DIRS[$name]}"

    echo -e "\n${GREEN}▲ Starting${RESET} ${BOLD}${name}${RESET}  (${dir})"

    if [[ ! -d "$dir" ]]; then
        echo -e "  ${RED}✗ Directory not found: ${dir}${RESET}"
        return 1
    fi

    cd "$dir"

    if [[ -n "${STACK_FILES[$name]:-}" ]]; then
        local file_flags=()
        for f in ${STACK_FILES[$name]}; do
            file_flags+=(-f "$f")
        done
        sudo docker compose "${file_flags[@]}" up -d --force-recreate
    else
        sudo docker compose up -d --force-recreate
    fi

    echo -e "  ${GREEN}✓ Done${RESET}"
}

stack_down() {
    local name="$1"
    local dir="$BASE_DIR/${STACK_DIRS[$name]}"

    echo -e "\n${YELLOW}▼ Stopping${RESET} ${BOLD}${name}${RESET}  (${dir})"

    if [[ ! -d "$dir" ]]; then
        echo -e "  ${RED}✗ Directory not found: ${dir}${RESET}"
        return 1
    fi

    cd "$dir"

    if [[ -n "${STACK_FILES[$name]:-}" ]]; then
        local file_flags=()
        for f in ${STACK_FILES[$name]}; do
            file_flags+=(-f "$f")
        done
        sudo docker compose "${file_flags[@]}" down
    else
        sudo docker compose down
    fi

    echo -e "  ${YELLOW}✓ Stopped${RESET}"
}

# ─── Arg parsing ──────────────────────────────────────────────────────────────
[[ $# -lt 1 ]] && usage

COMMAND="$1"
TARGET="${2:-}"

[[ "$COMMAND" != "up" && "$COMMAND" != "down" ]] && {
    echo -e "${RED}Error:${RESET} command must be 'up' or 'down'"
    usage
}

if [[ -n "$TARGET" ]]; then
    # Single stack
    if [[ -z "${STACK_DIRS[$TARGET]:-}" ]]; then
        echo -e "${RED}Error:${RESET} unknown stack '${TARGET}'"
        echo -e "Run $(basename "$0") without args to see available stacks."
        exit 1
    fi
    [[ "$COMMAND" == "up" ]] && stack_up "$TARGET" || stack_down "$TARGET"
else
    # All stacks — respect explicit order
    if [[ "$COMMAND" == "down" ]]; then
        mapfile -t ORDER < <(printf '%s\n' "${STACK_ORDER[@]}" | tac)
    else
        ORDER=("${STACK_ORDER[@]}")
    fi

    FAILED=()
    for name in "${ORDER[@]}"; do
        if [[ "$COMMAND" == "up" ]]; then
            stack_up "$name" || FAILED+=("$name")
        else
            stack_down "$name" || FAILED+=("$name")
        fi
    done

    echo
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        echo -e "${RED}✗ Failed stacks: ${FAILED[*]}${RESET}"
        exit 1
    else
        echo -e "${GREEN}✓ All stacks ${COMMAND} complete${RESET}"
    fi
fi
