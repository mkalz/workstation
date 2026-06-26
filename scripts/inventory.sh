#!/usr/bin/env bash
set -euo pipefail

ROOT="inventory"

SYSTEM="$ROOT/system"
DEV="$ROOT/development"
EDITOR="$ROOT/editor"
SHELLDIR="$ROOT/shell"
APPS="$ROOT/applications"

echo "Preparing inventory..."

rm -rf "$ROOT"

mkdir -p "$SYSTEM"
mkdir -p "$DEV"
mkdir -p "$EDITOR"
mkdir -p "$SHELLDIR"
mkdir -p "$APPS"

echo "Collecting system information..."

system_profiler SPHardwareDataType > "$SYSTEM/hardware.txt"
sw_vers > "$SYSTEM/macos.txt"

brew leaves | sort > "$SYSTEM/brew.txt"
brew list --cask | sort > "$SYSTEM/casks.txt"

if command -v mas >/dev/null 2>&1; then
    mas list > "$SYSTEM/mas.txt" 2>/dev/null || true
fi

system_profiler SPFontsDataType > "$SYSTEM/fonts.txt" 2>/dev/null || true

echo "Collecting development tools..."

git --version > "$DEV/git.txt"
git config --global --list > "$DEV/git-config.txt" 2>/dev/null || true

if command -v gh >/dev/null 2>&1; then
    gh auth status > "$DEV/github.txt" 2>&1 || true
fi

python3 --version > "$DEV/python.txt" 2>&1 || true
pip3 list >> "$DEV/python.txt" 2>&1 || true

if command -v uv >/dev/null 2>&1; then
    uv --version > "$DEV/uv.txt" 2>&1 || true
fi

if command -v R >/dev/null 2>&1; then
    R --version > "$DEV/r.txt" 2>&1 || true
fi

if command -v node >/dev/null 2>&1; then
    node --version > "$DEV/node.txt" 2>&1 || true
fi

if command -v go >/dev/null 2>&1; then
    go version > "$DEV/go.txt" 2>&1 || true
fi

if command -v docker >/dev/null 2>&1; then
    docker version > "$DEV/docker.txt" 2>&1 || true
fi

echo "Collecting editor configuration..."

if command -v code >/dev/null 2>&1; then
    code --list-extensions | sort > "$EDITOR/vscode-extensions.txt" 2>/dev/null || true
fi

if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
    cp "$HOME/Library/Application Support/Code/User/settings.json" "$EDITOR/vscode-settings.json"
fi

echo "Collecting shell configuration..."

if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$SHELLDIR/zshrc"
fi

if [ -f "$HOME/.zprofile" ]; then
    cp "$HOME/.zprofile" "$SHELLDIR/zprofile"
fi

if [ -f "$HOME/.zshenv" ]; then
    cp "$HOME/.zshenv" "$SHELLDIR/zshenv"
fi

alias > "$SHELLDIR/aliases.txt" 2>/dev/null || true

echo "Collecting installed applications..."

find /Applications -maxdepth 1 -name "*.app" \
    | sed 's#.*/##' \
    | sort > "$APPS/applications.txt"

launchctl list > "$APPS/launchagents.txt" 2>/dev/null || true

echo "Creating summary..."

cat > "$ROOT/summary.md" <<EOF
# Workstation Inventory

Generated: $(date)

## Sections

- System
- Development
- Editor
- Shell
- Applications

This inventory documents the current state of the existing workstation.

It is intended to support migration to a new workstation.

It does not imply that everything listed here should be migrated.
EOF

echo
echo "Inventory successfully written to:"
echo "  $ROOT"
echo
find "$ROOT" -type f | sort