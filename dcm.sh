#!/usr/bin/env bash
# dcm.sh — Docker Compose Manager
# Usage: dcm.sh <up|down|restart|update> [stack_name]

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
# Repo/base directory: defaults to the git repo root, falling back to this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${DCM_REPO_ROOT:-$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$SCRIPT_DIR")}"
BASE_DIR="${DCM_BASE_DIR:-$REPO_ROOT}"

# Load repo-level defaults, including DCM_INCLUDE/DCM_EXCLUDE, before command handling.
# Existing stack .env files are still loaded by Docker Compose from each stack directory.
DCM_ENV_FILE="${DCM_ENV_FILE:-$REPO_ROOT/.env}"
DCM_INCLUDE_WAS_SET=0
DCM_EXCLUDE_WAS_SET=0
if [[ ${DCM_INCLUDE+x} ]]; then
    DCM_INCLUDE_WAS_SET=1
    DCM_INCLUDE_FROM_ENV="$DCM_INCLUDE"
fi
if [[ ${DCM_EXCLUDE+x} ]]; then
    DCM_EXCLUDE_WAS_SET=1
    DCM_EXCLUDE_FROM_ENV="$DCM_EXCLUDE"
fi
if [[ -f "$DCM_ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$DCM_ENV_FILE"
    set +a
fi
if [[ "$DCM_INCLUDE_WAS_SET" -eq 1 ]]; then
    DCM_INCLUDE="$DCM_INCLUDE_FROM_ENV"
fi
if [[ "$DCM_EXCLUDE_WAS_SET" -eq 1 ]]; then
    DCM_EXCLUDE="$DCM_EXCLUDE_FROM_ENV"
fi

# Stack order: traefik first up, last down
# To add a new stack: append to STACK_ORDER and add an entry in STACK_DIRS (and optionally STACK_FILES)
STACK_ORDER=(traefik qbit arr jellyfin books nextcloud immich devs tools ai kiwix infra cloudflared)

declare -A STACK_DIRS=(
    [traefik]="traefik"
    [nextcloud]="nextcloud"
    [immich]="immich"
    [infra]="infras"
    [arr]="jellyfin-stack"
    [qbit]="jellyfin-stack"
    [jellyfin]="jellyfin-stack"
    [kiwix]="kiwix"
    [tools]="tools"
    [cloudflared]="cloudflared"
    [devs]="devs"
    [books]="books"
    [ai]="ai"
)

# Optional: override compose files per stack (space-separated)
# If not defined here, defaults to standard "docker compose" with no -f flag
declare -A STACK_FILES=(
    [arr]="arr.docker-compose.yml"
    [qbit]="qbit.docker-compose.yml"
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
    echo -e "${BOLD}Usage:${RESET} $(basename "$0") <up|down|restart> [stack]"
    echo
    echo -e "${BOLD}Commands:${RESET}"
    echo -e "  up       Start all stacks (or a specific one)"
    echo -e "  down     Stop all stacks (or a specific one)"
    echo -e "  restart  Down then up all stacks (or a specific one)"
    echo -e "  update   Pull latest images then restart all stacks (or a specific one)"
    echo
    echo -e "${BOLD}Available stacks:${RESET}"
    for key in "${!STACK_DIRS[@]}"; do
        local files="${STACK_FILES[$key]:-default}"
        printf "  ${CYAN}%-12s${RESET} →  %s  (%s)\n" "$key" "${STACK_DIRS[$key]}" "$files"
    done | sort
    echo
    echo -e "${BOLD}Startup order:${RESET}  ${STACK_ORDER[*]}"
    echo -e "${BOLD}Shutdown order:${RESET} $(printf '%s\n' "${STACK_ORDER[@]}" | tac | tr '\n' ' ')"
    echo -e "${BOLD}Active filter:${RESET} include='${DCM_INCLUDE:-}' exclude='${DCM_EXCLUDE:-}'"
    echo -e "${BOLD}Filter vars:${RESET}   DCM_INCLUDE, DCM_EXCLUDE (comma or space separated; exclude wins)"
    echo
    echo -e "${BOLD}Examples:${RESET}"
    echo -e "  $(basename "$0") up"
    echo -e "  $(basename "$0") down jellyfin"
    echo -e "  $(basename "$0") up nextcloud"
    echo -e "  $(basename "$0") restart"
    echo -e "  $(basename "$0") restart arr"
    echo -e "  $(basename "$0") update"
    echo -e "  $(basename "$0") update arr"
    exit 1
}

split_stack_list() {
    local raw="$1"
    raw="${raw//,/ }"
    for name in $raw; do
        printf '%s\n' "$name"
    done
}

contains_stack() {
    local needle="$1"
    shift

    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done

    return 1
}

validate_stack_filter() {
    local var_name="$1"
    local raw="$2"

    [[ -z "$raw" ]] && return 0

    local name
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        if [[ -z "${STACK_DIRS[$name]:-}" ]]; then
            echo -e "${RED}Error:${RESET} ${var_name} contains unknown stack '${name}'" >&2
            exit 1
        fi
    done < <(split_stack_list "$raw")
}

selected_stacks() {
    local include_raw="${DCM_INCLUDE:-}"
    local exclude_raw="${DCM_EXCLUDE:-}"
    local includes=()
    local excludes=()

    if [[ -n "$include_raw" ]]; then
        mapfile -t includes < <(split_stack_list "$include_raw")
    fi

    if [[ -n "$exclude_raw" ]]; then
        mapfile -t excludes < <(split_stack_list "$exclude_raw")
    fi

    local name
    for name in "${STACK_ORDER[@]}"; do
        if [[ ${#includes[@]} -gt 0 ]] && ! contains_stack "$name" "${includes[@]}"; then
            continue
        fi

        if [[ ${#excludes[@]} -gt 0 ]] && contains_stack "$name" "${excludes[@]}"; then
            continue
        fi

        printf '%s\n' "$name"
    done
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

stack_pull() {
    local name="$1"
    local dir="$BASE_DIR/${STACK_DIRS[$name]}"

    echo -e "\n${CYAN}⬇ Pulling${RESET} ${BOLD}${name}${RESET}  (${dir})"

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
        sudo docker compose "${file_flags[@]}" pull
    else
        sudo docker compose pull
    fi

    echo -e "  ${GREEN}✓ Pulled${RESET}"
}

stack_update() {
    local name="$1"
    echo -e "\n${CYAN}⟳ Updating${RESET} ${BOLD}${name}${RESET}"
    stack_pull "$name" && stack_restart "$name"
}

stack_restart() {
    local name="$1"
    echo -e "\n${CYAN}↺ Restarting${RESET} ${BOLD}${name}${RESET}"
    stack_down "$name" && stack_up "$name"
}

# ─── Arg parsing ──────────────────────────────────────────────────────────────
[[ $# -lt 1 ]] && usage

COMMAND="$1"
TARGET="${2:-}"

[[ "$COMMAND" != "up" && "$COMMAND" != "down" && "$COMMAND" != "restart" && "$COMMAND" != "update" ]] && {
    echo -e "${RED}Error:${RESET} command must be 'up', 'down', 'restart', or 'update'"
    usage
}

if [[ -n "$TARGET" ]]; then
    # Single stack
    if [[ -z "${STACK_DIRS[$TARGET]:-}" ]]; then
        echo -e "${RED}Error:${RESET} unknown stack '${TARGET}'"
        echo -e "Run $(basename "$0") without args to see available stacks."
        exit 1
    fi
    case "$COMMAND" in
        up)      stack_up "$TARGET" ;;
        down)    stack_down "$TARGET" ;;
        restart) stack_restart "$TARGET" ;;
        update)  stack_update "$TARGET" ;;
    esac
else
    # All selected stacks — respect explicit order
    FAILED=()
    validate_stack_filter "DCM_INCLUDE" "${DCM_INCLUDE:-}"
    validate_stack_filter "DCM_EXCLUDE" "${DCM_EXCLUDE:-}"
    mapfile -t SELECTED_STACKS < <(selected_stacks)

    if [[ ${#SELECTED_STACKS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No stacks selected after applying DCM_INCLUDE/DCM_EXCLUDE.${RESET}"
        exit 0
    fi

    if [[ -n "${DCM_INCLUDE:-}${DCM_EXCLUDE:-}" ]]; then
        echo -e "${CYAN}Selected stacks:${RESET} ${SELECTED_STACKS[*]}"
    fi

    if [[ "$COMMAND" == "update" ]]; then
        echo -e "${CYAN}⟳ Updating selected stacks${RESET}"

        for name in "${SELECTED_STACKS[@]}"; do
            stack_pull "$name" || FAILED+=("$name (pull)")
        done

        if [[ ${#FAILED[@]} -eq 0 ]]; then
            echo -e "\n${CYAN}↺ Restarting selected stacks after update${RESET}"

            mapfile -t DOWN_ORDER < <(printf '%s\n' "${SELECTED_STACKS[@]}" | tac)
            for name in "${DOWN_ORDER[@]}"; do
                stack_down "$name" || FAILED+=("$name (down)")
            done

            echo
            for name in "${SELECTED_STACKS[@]}"; do
                stack_up "$name" || FAILED+=("$name (up)")
            done
        fi
    elif [[ "$COMMAND" == "restart" ]]; then
        # Down in reverse order, then up in forward order
        echo -e "${CYAN}↺ Restarting selected stacks${RESET}"

        mapfile -t DOWN_ORDER < <(printf '%s\n' "${SELECTED_STACKS[@]}" | tac)
        for name in "${DOWN_ORDER[@]}"; do
            stack_down "$name" || FAILED+=("$name (down)")
        done

        echo
        for name in "${SELECTED_STACKS[@]}"; do
            stack_up "$name" || FAILED+=("$name (up)")
        done
    elif [[ "$COMMAND" == "down" ]]; then
        mapfile -t ORDER < <(printf '%s\n' "${SELECTED_STACKS[@]}" | tac)
        for name in "${ORDER[@]}"; do
            stack_down "$name" || FAILED+=("$name")
        done
    else
        for name in "${SELECTED_STACKS[@]}"; do
            stack_up "$name" || FAILED+=("$name")
        done
    fi

    echo
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        echo -e "${RED}✗ Failed stacks: ${FAILED[*]}${RESET}"
        exit 1
    else
        echo -e "${GREEN}✓ Selected stacks ${COMMAND} complete${RESET}"
    fi

fi
