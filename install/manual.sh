#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  install/manual.sh [--dry-run]

Options:
  --dry-run   Show manual setup steps without changing the system.
  -h, --help  Show this help message.
EOF
}

log_section() {
  printf "\n==> %s\n" "$1"
}

log_step() {
  printf "→ %s\n" "$1"
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

log_section "Manual setup steps"

log_step "Sign in to iCloud."
log_step "Sign in to the Mac App Store."
log_step "Sign in to password manager."
log_step "Sign in to browser sync."
log_step "Sign in to academic and research services as needed."
log_step "Review application-specific license activations."