#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
FINDER_RESTART_NEEDED=0
DOCK_RESTART_NEEDED=0

usage() {
  cat <<'EOF'
Usage:
  install/macos.sh [--dry-run]

Options:
  --dry-run   Show macOS default changes without modifying the system.
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

format_defaults_flag() {
  local value_type="$1"

  case "$value_type" in
    bool)
      printf -- "-bool"
      ;;
    int)
      printf -- "-int"
      ;;
    float)
      printf -- "-float"
      ;;
    string)
      printf -- "-string"
      ;;
    *)
      printf "ERROR: Unsupported macOS defaults type: %s\n" "$value_type" >&2
      exit 1
      ;;
  esac
}

read_current_default() {
  local domain="$1"
  local key="$2"

  defaults read "$domain" "$key" 2>/dev/null || true
}

normalize_expected_value() {
  local value_type="$1"
  local value="$2"

  case "$value_type" in
    bool)
      if [[ "$value" == "true" ]]; then
        printf "1"
      elif [[ "$value" == "false" ]]; then
        printf "0"
      else
        printf "%s" "$value"
      fi
      ;;
    *)
      printf "%s" "$value"
      ;;
  esac
}

mark_restart_if_needed() {
  local domain="$1"

  case "$domain" in
    com.apple.finder)
      FINDER_RESTART_NEEDED=1
      ;;
    com.apple.dock)
      DOCK_RESTART_NEEDED=1
      ;;
  esac
}

apply_default() {
  local domain="$1"
  local key="$2"
  local value_type="$3"
  local value="$4"

  local current_value
  local expected_value
  local defaults_flag

  current_value="$(read_current_default "$domain" "$key")"
  expected_value="$(normalize_expected_value "$value_type" "$value")"
  defaults_flag="$(format_defaults_flag "$value_type")"

  if [[ "$current_value" == "$expected_value" ]]; then
    log_ok "macOS default already configured: $domain $key=$value"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_step "Would set macOS default: $domain $key=$value"
    mark_restart_if_needed "$domain"
  else
    defaults write "$domain" "$key" "$defaults_flag" "$value"
    log_ok "Set macOS default: $domain $key=$value"
    mark_restart_if_needed "$domain"
  fi
}

restart_app() {
  local app_name="$1"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_step "Would restart $app_name to apply changes"
  else
    killall "$app_name" >/dev/null 2>&1 || true
    log_ok "Restarted $app_name"
  fi
}

restart_affected_apps() {
  if [[ "$FINDER_RESTART_NEEDED" -eq 1 ]]; then
    restart_app "Finder"
  fi

  if [[ "$DOCK_RESTART_NEEDED" -eq 1 ]]; then
    restart_app "Dock"
  fi
}

load_macos_defaults() {
  local defaults_output="$1"

  if ! uv run python "$ROOT_DIR/scripts/read-macos-defaults.py" >"$defaults_output"; then
    printf "ERROR: Failed to read macOS defaults configuration.\n" >&2
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

log_section "macOS defaults"

require_command "defaults" "macOS defaults command"
require_command "uv" "uv"

DEFAULTS_OUTPUT="$(mktemp)"
trap 'rm -f "$DEFAULTS_OUTPUT"' EXIT

load_macos_defaults "$DEFAULTS_OUTPUT"

while IFS=$'\t' read -r domain key value_type value; do
  if [[ -n "$domain" ]]; then
    apply_default "$domain" "$key" "$value_type" "$value"
  fi
done <"$DEFAULTS_OUTPUT"

restart_affected_apps