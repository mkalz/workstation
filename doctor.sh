#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ERRORS=0
WARNINGS=0
CHECK_LOG="/tmp/workstation-doctor-check.log"

print_header() {
  printf "\n%s\n" "$1"
  printf "%s\n" "----------------------------------------------------------------------"
}

ok() {
  printf "✓ %s\n" "$1"
}

warn() {
  printf "⚠ %s\n" "$1"
  WARNINGS=$((WARNINGS + 1))
}

fail() {
  printf "✗ %s\n" "$1"
  ERRORS=$((ERRORS + 1))
}

print_command_hint() {
  local command_name="$1"

  case "$command_name" in
    git|make)
      cat <<'EOF'
  Hint:
    Install Xcode Command Line Tools:

    xcode-select --install
EOF
      ;;
    uv)
      cat <<'EOF'
  Hint:
    Install uv with Homebrew:

    brew install uv
EOF
      ;;
    brew)
      cat <<'EOF'
  Hint:
    Install Homebrew from https://brew.sh
EOF
      ;;
    code)
      cat <<'EOF'
  Hint:
    Install Visual Studio Code and enable the shell command:

    In VS Code: Command Palette → Shell Command: Install 'code' command in PATH
EOF
      ;;
    *)
      cat <<EOF
  Hint:
    Install the missing command: $command_name
EOF
      ;;
  esac
}

require_command() {
  local command_name="$1"
  local description="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    ok "$description found: $(command -v "$command_name")"
  else
    fail "$description not found. Missing command: $command_name"
    print_command_hint "$command_name"
  fi
}

check_file() {
  local path="$1"
  local description="$2"

  if [[ -f "$path" ]]; then
    ok "$description exists: $path"
  else
    fail "$description missing: $path"

    cat <<EOF
  Hint:
    Expected file:
    $path
EOF

    if [[ "$(basename "$path")" == "Brewfile" ]]; then
      cat <<'EOF'

    Regenerate it with:
    make generate-brewfile
EOF
    else
      cat <<'EOF'

    Restore the file from Git or recreate it from the repository template.
EOF
    fi
  fi
}

check_directory() {
  local path="$1"
  local description="$2"

  if [[ -d "$path" ]]; then
    ok "$description exists: $path"
  else
    fail "$description missing: $path"

    cat <<EOF
  Hint:
    Create the directory:

    mkdir -p "$path"

    If the directory should be versioned while empty, add a placeholder:

    touch "$path/.gitkeep"
EOF
  fi
}

check_executable_file() {
  local path="$1"
  local description="$2"

  if [[ ! -f "$path" ]]; then
    fail "$description missing: $path"

    cat <<EOF
  Hint:
    Expected executable file:
    $path
EOF

    return
  fi

  if [[ ! -x "$path" ]]; then
    fail "$description is not executable: $path"

    cat <<EOF
  Hint:
    Make it executable:

    chmod +x "$path"
EOF

    return
  fi

  ok "$description is executable: $path"
}

run_check() {
  local description="$1"
  local hint="$2"
  shift 2

  if "$@" >"$CHECK_LOG" 2>&1; then
    ok "$description"
  else
    fail "$description"
    sed 's/^/  /' "$CHECK_LOG"

    if [[ -n "$hint" ]]; then
      printf "\n  Hint:\n"
      printf "    %s\n" "$hint"
    fi
  fi
}

print_header "Workstation doctor"

printf "Repository: %s\n" "$ROOT_DIR"

print_header "Core tools"

require_command "git" "Git"
require_command "bash" "Bash"
require_command "make" "Make"
require_command "uv" "uv"
require_command "defaults" "macOS defaults command"

if command -v brew >/dev/null 2>&1; then
  ok "Homebrew found: $(command -v brew)"
else
  warn "Homebrew not found. This is expected before the first bootstrap run."
  print_command_hint "brew"
fi

if command -v code >/dev/null 2>&1; then
  ok "VS Code command found: $(command -v code)"
else
  warn "VS Code command not found. VS Code extensions cannot be installed until 'code' is available."
  print_command_hint "code"
fi

print_header "Repository structure"

check_file "$ROOT_DIR/Makefile" "Makefile"
check_file "$ROOT_DIR/README.md" "README"
check_file "$ROOT_DIR/pyproject.toml" "Python project configuration"
check_executable_file "$ROOT_DIR/bootstrap.sh" "Bootstrap script"
check_executable_file "$ROOT_DIR/doctor.sh" "Doctor script"
check_file "$ROOT_DIR/Brewfile" "Brewfile"

check_directory "$ROOT_DIR/config" "Configuration directory"
check_directory "$ROOT_DIR/scripts" "Scripts directory"
check_directory "$ROOT_DIR/install" "Install directory"
check_directory "$ROOT_DIR/inventory" "Inventory directory"
check_directory "$ROOT_DIR/tests" "Tests directory"
check_directory "$ROOT_DIR/docs" "Documentation directory"
check_directory "$ROOT_DIR/containers" "Containers directory"

print_header "Install modules"

check_executable_file "$ROOT_DIR/install/prerequisites.sh" "Prerequisites install module"
check_executable_file "$ROOT_DIR/install/homebrew.sh" "Homebrew install module"
check_executable_file "$ROOT_DIR/install/git.sh" "Git install module"
check_executable_file "$ROOT_DIR/install/macos.sh" "macOS defaults install module"
check_executable_file "$ROOT_DIR/install/vscode.sh" "VS Code install module"
check_executable_file "$ROOT_DIR/install/manual.sh" "Manual setup module"

print_header "Helper scripts"

check_executable_file "$ROOT_DIR/scripts/read-config.py" "Generic configuration reader"
check_executable_file "$ROOT_DIR/scripts/read-macos-defaults.py" "macOS defaults reader"
check_executable_file "$ROOT_DIR/scripts/validate-repository.py" "Repository hygiene validator"

print_header "Configuration validation"

run_check \
  "Configuration files are valid" \
  "Run: make validate-config" \
  make -C "$ROOT_DIR" validate-config

run_check \
  "Application manifest is valid and Brewfile is current" \
  "Run: make generate-brewfile && make validate-applications" \
  make -C "$ROOT_DIR" validate-applications

run_check \
  "Repository hygiene is valid" \
  "Run: make validate-repository" \
  make -C "$ROOT_DIR" validate-repository

run_check \
  "macOS defaults configuration is valid" \
  "Run: uv run python scripts/read-macos-defaults.py" \
  uv run python "$ROOT_DIR/scripts/read-macos-defaults.py"

print_header "Test suite"

run_check \
  "Python test suite passes" \
  "Run: make test" \
  make -C "$ROOT_DIR" test

print_header "Summary"

if [[ "$WARNINGS" -gt 0 ]]; then
  printf "Warnings: %s\n" "$WARNINGS"
fi

if [[ "$ERRORS" -gt 0 ]]; then
  printf "Errors: %s\n" "$ERRORS"
  exit 1
fi

printf "System looks good.\n"
exit 0