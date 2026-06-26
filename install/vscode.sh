#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0

VSCODE_SETTINGS_SOURCE="$ROOT_DIR/config/vscode/settings.json"
VSCODE_KEYBINDINGS_SOURCE="$ROOT_DIR/config/vscode/keybindings.json"
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS_TARGET="$VSCODE_USER_DIR/settings.json"
VSCODE_KEYBINDINGS_TARGET="$VSCODE_USER_DIR/keybindings.json"

usage() {
  cat <<'EOF'
Usage:
  install/vscode.sh [--dry-run]

Options:
  --dry-run   Show VS Code configuration changes without modifying VS Code.
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

log_warn() {
  printf "⚠ %s\n" "$1"
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

install_user_file() {
  local source_file="$1"
  local target_file="$2"
  local description="$3"

  if [[ ! -f "$source_file" ]]; then
    log_warn "$description source not found: $source_file"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_step "Would ensure VS Code user directory exists: $VSCODE_USER_DIR"

    if [[ -f "$target_file" ]]; then
      if cmp -s "$source_file" "$target_file"; then
        log_ok "$description already up to date: $target_file"
      else
        log_step "Would back up existing $description and install repository version"
      fi
    else
      log_step "Would install $description: $target_file"
    fi

    return 0
  fi

  mkdir -p "$VSCODE_USER_DIR"

  if [[ -f "$target_file" ]]; then
    if cmp -s "$source_file" "$target_file"; then
      log_ok "$description already up to date: $target_file"
      return 0
    fi

    local backup_file
    backup_file="$target_file.backup.$(date +%Y%m%d%H%M%S)"
    cp "$target_file" "$backup_file"
    log_ok "Backed up existing $description: $backup_file"
  fi

  cp "$source_file" "$target_file"
  log_ok "Installed $description: $target_file"
}

is_extension_installed() {
  local extension="$1"

  code --list-extensions | grep -Fxq "$extension"
}

install_extension() {
  local extension="$1"

  if is_extension_installed "$extension"; then
    log_ok "VS Code extension already installed: $extension"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_step "Would install VS Code extension: $extension"
  else
    code --install-extension "$extension"
    log_ok "Installed VS Code extension: $extension"
  fi
}

install_extensions() {
  if ! command -v code >/dev/null 2>&1; then
    log_warn "VS Code command not found. Skipping VS Code extension installation."
    cat <<'EOF'
  Hint:
    Install Visual Studio Code and enable the shell command:

    In VS Code: Command Palette → Shell Command: Install 'code' command in PATH
EOF
    return 0
  fi

  log_ok "VS Code command found: $(command -v code)"

  while IFS= read -r extension; do
    if [[ -n "$extension" ]]; then
      install_extension "$extension"
    fi
  done < <(uv run python "$ROOT_DIR/scripts/read-config.py" vscode extensions)
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

log_section "VS Code"

require_command "uv" "uv"

install_user_file "$VSCODE_SETTINGS_SOURCE" "$VSCODE_SETTINGS_TARGET" "VS Code settings"
install_user_file "$VSCODE_KEYBINDINGS_SOURCE" "$VSCODE_KEYBINDINGS_TARGET" "VS Code keybindings"
install_extensions