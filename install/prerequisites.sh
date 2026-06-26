#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install/prerequisites.sh [--dry-run]

Options:
  --dry-run   Check prerequisites without changing the system.
  -h, --help  Show this help message.
EOF
}

log_section() {
  printf "\n==> %s\n" "$1"
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

parse_arguments() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --dry-run)
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

log_section "Prerequisites"

require_command "git" "Git"
require_command "make" "Make"