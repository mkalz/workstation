#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh [--dry-run]

Options:
  --dry-run   Show what would be done without changing the system.
  -h, --help  Show this help message.
EOF
}

log_section() {
  printf "\n==> %s\n" "$1"
}

log_ok() {
  printf "✓ %s\n" "$1"
}

run_module() {
  local module="$1"

  if [[ ! -x "$ROOT_DIR/$module" ]]; then
    printf "ERROR: Install module is missing or not executable: %s\n" "$module" >&2
    exit 1
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    "$ROOT_DIR/$module" --dry-run
  else
    "$ROOT_DIR/$module"
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

log_section "Bootstrap"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log_ok "Dry-run mode enabled. No system changes will be made."
fi

run_module "install/prerequisites.sh"
run_module "install/homebrew.sh"
run_module "install/git.sh"
run_module "install/macos.sh"
run_module "install/vscode.sh"
run_module "install/manual.sh"

log_section "Doctor"

"$ROOT_DIR/doctor.sh"

log_section "Done"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log_ok "Dry-run completed."
else
  log_ok "Bootstrap completed."
fi