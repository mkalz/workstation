#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  install/homebrew.sh [--dry-run]

Options:
  --dry-run   Show Homebrew actions without changing the system.
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

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf "DRY-RUN: %s\n" "$*"
  else
    "$@"
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log_ok "Homebrew found: $(command -v brew)"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_step "Would install Homebrew"
    return 0
  fi

  printf "ERROR: Homebrew is not installed.\n" >&2
  printf "Install Homebrew first from https://brew.sh and rerun ./bootstrap.sh.\n" >&2
  exit 1
}

ensure_uv() {
  if command -v uv >/dev/null 2>&1; then
    log_ok "uv found: $(command -v uv)"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_step "Would install uv with Homebrew"
    return 0
  fi

  log_step "Installing uv with Homebrew"
  brew install uv
  log_ok "uv installed: $(command -v uv)"
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

log_section "Homebrew"

ensure_homebrew
ensure_uv

log_section "Validation"

run make -C "$ROOT_DIR" validate
run make -C "$ROOT_DIR" test

log_section "Homebrew bundle"

if [[ -f "$ROOT_DIR/Brewfile" ]]; then
  run brew bundle --file "$ROOT_DIR/Brewfile"
else
  printf "ERROR: Brewfile missing: %s\n" "$ROOT_DIR/Brewfile" >&2
  exit 1
fi