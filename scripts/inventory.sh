#!/usr/bin/env bash
set -euo pipefail

ROOT="inventory"

SYSTEM="$ROOT/system"
DEV="$ROOT/development"
EDITOR="$ROOT/editor"
SHELLDIR="$ROOT/shell"
APPS="$ROOT/applications"
SECURITY="$ROOT/security"

count_lines() {
    local file="$1"
    if [ -f "$file" ]; then
        wc -l < "$file" | tr -d ' '
    else
        echo "0"
    fi
}

echo "Preparing inventory..."

rm -rf "$ROOT"

mkdir -p "$SYSTEM"
mkdir -p "$DEV"
mkdir -p "$EDITOR"
mkdir -p "$SHELLDIR"
mkdir -p "$APPS"
mkdir -p "$SECURITY"
mkdir -p "$SECURITY/ssh"

echo "Collecting system information..."

system_profiler SPHardwareDataType > "$SYSTEM/hardware.txt" 2>/dev/null || true
sw_vers > "$SYSTEM/macos.txt" 2>/dev/null || true

brew leaves | sort > "$SYSTEM/brew.txt" 2>/dev/null || true
brew list --cask | sort > "$SYSTEM/casks.txt" 2>/dev/null || true
brew tap | sort > "$SYSTEM/taps.txt" 2>/dev/null || true
brew services list > "$SYSTEM/services.txt" 2>/dev/null || true

if command -v mas >/dev/null 2>&1; then
    mas list > "$SYSTEM/mas.txt" 2>/dev/null || true
else
    : > "$SYSTEM/mas.txt"
fi

system_profiler SPFontsDataType > "$SYSTEM/fonts.txt" 2>/dev/null || true

echo "Collecting development tools..."

git --version > "$DEV/git.txt" 2>/dev/null || true
git config --global --list > "$DEV/git-config.txt" 2>/dev/null || true

if command -v gh >/dev/null 2>&1; then
    gh auth status > "$DEV/github.txt" 2>&1 || true
else
    echo "GitHub CLI not found." > "$DEV/github.txt"
fi

python3 --version > "$DEV/python.txt" 2>&1 || true
pip3 list >> "$DEV/python.txt" 2>&1 || true

if command -v uv >/dev/null 2>&1; then
    uv --version > "$DEV/uv.txt" 2>&1 || true
else
    echo "uv not found." > "$DEV/uv.txt"
fi

if command -v R >/dev/null 2>&1; then
    R --version > "$DEV/r.txt" 2>&1 || true
else
    echo "R not found." > "$DEV/r.txt"
fi

if command -v node >/dev/null 2>&1; then
    node --version > "$DEV/node.txt" 2>&1 || true
else
    echo "Node not found." > "$DEV/node.txt"
fi

if command -v go >/dev/null 2>&1; then
    go version > "$DEV/go.txt" 2>&1 || true
else
    echo "Go not found." > "$DEV/go.txt"
fi

if command -v docker >/dev/null 2>&1; then
    docker version > "$DEV/docker.txt" 2>&1 || true
    docker ps -a > "$DEV/docker-containers.txt" 2>/dev/null || true
    docker images > "$DEV/docker-images.txt" 2>/dev/null || true
    docker volume ls > "$DEV/docker-volumes.txt" 2>/dev/null || true
else
    echo "Docker not found." > "$DEV/docker.txt"
    : > "$DEV/docker-containers.txt"
    : > "$DEV/docker-images.txt"
    : > "$DEV/docker-volumes.txt"
fi

echo "Collecting editor configuration..."

if command -v code >/dev/null 2>&1; then
    code --list-extensions | sort > "$EDITOR/vscode-extensions.txt" 2>/dev/null || true
else
    : > "$EDITOR/vscode-extensions.txt"
fi

if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
    cp "$HOME/Library/Application Support/Code/User/settings.json" "$EDITOR/vscode-settings.json"
else
    echo "{}" > "$EDITOR/vscode-settings.json"
fi

echo "Collecting shell metadata..."

{
    echo "# Shell Inventory"
    echo
    echo "Generated: $(date)"
    echo
    echo "## Existing shell files"
    echo
    for file in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zshenv" "$HOME/.zlogin" "$HOME/.zlogout"; do
        if [ -f "$file" ]; then
            printf -- "- %s\n" "$(basename "$file")"
        fi
    done
    echo
    echo "## PATH entries"
    echo
    echo "$PATH" | tr ':' '\n'
} > "$SHELLDIR/shell-summary.md"

{
    echo "# Shell Secrets Policy"
    echo
    echo "Shell startup files are intentionally not copied into this inventory."
    echo
    echo "Files such as .zshrc, .zprofile, .zshenv, aliases, and local shell snippets may contain API keys, tokens, private paths, or other secrets."
    echo
    echo "Migration must be performed manually after reviewing and sanitizing the source files."
} > "$SECURITY/shell-secrets-policy.md"

echo "Collecting SSH metadata..."

if [ -d "$HOME/.ssh" ]; then
    find "$HOME/.ssh" -maxdepth 1 -type f \
        -exec basename {} \; \
        | sort > "$SECURITY/ssh/files.txt"

    find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub" \
        -exec basename {} \; \
        | sort > "$SECURITY/ssh/public-key-files.txt"
else
    : > "$SECURITY/ssh/files.txt"
    : > "$SECURITY/ssh/public-key-files.txt"
fi

echo "Collecting installed applications..."

find /Applications -maxdepth 1 -name "*.app" \
    | sed 's#.*/##' \
    | sort > "$APPS/applications.txt" 2>/dev/null || true

if [ -d "$HOME/Applications" ]; then
    find "$HOME/Applications" -maxdepth 1 -name "*.app" \
        | sed 's#.*/##' \
        | sort > "$APPS/user-applications.txt" 2>/dev/null || true
else
    : > "$APPS/user-applications.txt"
fi

launchctl list > "$APPS/launchagents.txt" 2>/dev/null || true

BREW_COUNT="$(count_lines "$SYSTEM/brew.txt")"
CASK_COUNT="$(count_lines "$SYSTEM/casks.txt")"
MAS_COUNT="$(count_lines "$SYSTEM/mas.txt")"
VSCODE_COUNT="$(count_lines "$EDITOR/vscode-extensions.txt")"
APP_COUNT="$(count_lines "$APPS/applications.txt")"
USER_APP_COUNT="$(count_lines "$APPS/user-applications.txt")"
SSH_FILE_COUNT="$(count_lines "$SECURITY/ssh/files.txt")"

echo "Creating summary..."

cat > "$ROOT/summary.md" <<EOF
# Workstation Inventory

Generated: $(date)

## Purpose

This inventory documents the current state of the existing workstation.

It is intended to support migration to a new workstation.

It does not imply that everything listed here should be migrated.

## Summary

| Area | Count |
|---|---:|
| Homebrew formulae | $BREW_COUNT |
| Homebrew casks | $CASK_COUNT |
| Mac App Store apps | $MAS_COUNT |
| VS Code extensions | $VSCODE_COUNT |
| Applications in /Applications | $APP_COUNT |
| Applications in ~/Applications | $USER_APP_COUNT |
| SSH files detected | $SSH_FILE_COUNT |

## Sections

- System
- Development
- Editor
- Shell metadata
- Applications
- Security metadata

## Security note

Shell startup files are not copied because they may contain secrets.

SSH private keys are not copied.

Public SSH key contents are not copied either; only public key filenames are recorded.

Review shell and SSH configuration manually before migrating anything to the new workstation.
EOF

echo
echo "Inventory successfully written to:"
echo "  $ROOT"
echo
find "$ROOT" -type f | sort