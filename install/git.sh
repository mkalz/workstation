#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  install/git.sh [--dry-run]

Options:
  --dry-run   Show Git configuration changes without modifying global Git config.
  -h, --help  Show this help message.
EOF
}

log_section() {
  printf "\n==> %s\n" "$1"
}

log_step() {
  printf "→ %s\n" "$1"
}

log_ok() {
  printf "✓ %s\n" "$1"
}

require_command() {
  local command_name="$1"
  local description="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    log_ok "$description found: $(command -v "$command_name")"
  else
    printf "ERROR: %s not found. Missing command: %s\n" "$description" "$command_name" >&2
    exit 1
  fi
}

apply_git_config() {
  local key="$1"
  local value="$2"
  local current_value=""

  current_value="$(git config --global --get "$key" || true)"

  if [[ "$current_value" == "$value" ]]; then
    log_ok "Git setting already configured: $key=$value"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_step "Would set Git setting: $key=$value"
  else
    git config --global "$key" "$value"
    log_ok "Set Git setting: $key=$value"
  fi
}

load_git_config() {
  local config_output="$1"

  if ! uv run python "$ROOT_DIR/scripts/read-git-config.py" >"$config_output"; then
    printf "ERROR: Failed to read Git configuration.\n" >&2
    printf "Hint: Try removing the local uv environment and rerun:\n" >&2
    printf "  rm -rf .venv\n" >&2
    printf "  uv run python --version\n" >&2
    exit 1
  fi
}

parse_arguments() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf "ERROR: Unknown argument: %s\n" "$1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

parse_arguments "$@"

log_section "Git configuration"

require_command "git" "Git"
require_command "uv" "uv"

CONFIG_OUTPUT="$(mktemp)"
trap 'rm -f "$CONFIG_OUTPUT"' EXIT

load_git_config "$CONFIG_OUTPUT"

while IFS=$'\t' read -r key value; do
  if [[ -n "$key" ]]; then
    apply_git_config "$key" "$value"
  fi
done <"$CONFIG_OUTPUT"