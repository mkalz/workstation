#!/usr/bin/env bash
set -euo pipefail

ROOT="inventory"

SYSTEM="$ROOT/system"
DEV="$ROOT/development"
EDITOR="$ROOT/editor"
SHELLDIR="$ROOT/shell"
APPS="$ROOT/applications"
SECURITY="$ROOT/security"

echo "Preparing inventory..."

rm -rf "$ROOT"

mkdir -p "$SYSTEM"
mkdir -p "$DEV"
mkdir -p "$EDITOR"
mkdir -p "$SHELLDIR"
mkdir -p "$APPS"
mkdir -p "$SECURITY"

echo "Collecting system information..."

system_profiler SPHardwareDataType > "$SYSTEM/hardware.txt"
sw_vers > "$SYSTEM/macos.txt"

brew leaves | sort > "$SYSTEM/brew.txt"
brew list --cask | sort > "$SYSTEM/casks.txt"
brew tap > "$SYSTEM/taps.txt"
brew services list > "$SYSTEM/services.txt" 2>/dev/null || true

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
    docker ps -a > "$DEV/docker-containers.txt" 2>/dev/null || true
    docker images > "$DEV/docker-images.txt" 2>/dev/null || true
    docker volume ls > "$DEV/docker-volumes.txt" 2>/dev/null || true
fi

echo "Collecting editor configuration..."

if command -v code >/dev/null 2>&1; then
    code --list-extensions | sort > "$EDITOR/vscode-extensions.txt" 2>/dev/null || true
fi

if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
    cp "$HOME/Library/Application Support/Code/User/settings.json" "$EDITOR/vscode-settings.json"
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
    echo "## PATH"
    echo
    echo "$PATH" | tr ':' '\n'
} > "$SHELLDIR/shell-summary.md"

{
    echo "# Shell Safety Note"
    echo
    echo "Shell startup files are intentionally not copied into this inventory."
    echo
    echo "Reason: files such as .zshrc, .zprofile, .zshenv, aliases, and local shell snippets may contain API keys, tokens, private paths, or other secrets."
    echo
    echo "Migration should be performed manually and only after reviewing and sanitizing the source files."
} > "$SECURITY/shell-secrets-policy.md"

echo "Collecting SSH metadata..."

mkdir -p "$SECURITY/ssh"

if [ -d "$HOME/.ssh" ]; then
    find "$HOME/.ssh" -maxdepth 1 -type f \
        -exec basename {} \; \
        | sort > "$SECURITY/ssh/files.txt"

    find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub" \
        -exec sh -c 'for f do echo "### $(basename "$f")"; cat "$f"; echo; done' sh {} + \
        > "$SECURITY/ssh/public-keys.txt" 2>/dev/null || true
fi

echo "Collecting installed applications..."

find /Applications -maxdepth 1 -name "*.app" \
    | sed 's#.*/##' \
    | sort > "$APPS/applications.txt"

if [ -d "$HOME/Applications" ]; then
    find "$HOME/Applications" -maxdepth 1 -name "*.app" \
        | sed 's#.*/##' \
        | sort > "$APPS/user-applications.txt"
fi

launchctl list > "$APPS/launchagents.txt" 2>/dev/null || true

echo "Creating summary..."

cat > "$ROOT/summary.md" <<EOF
# Workstation Inventory

Generated: $(date)

## Sections

- System
- Development
- Editor
- Shell metadata
- Applications
- Security metadata

This inventory documents the current state of the existing workstation.

It is intended to support migration to a new workstation.

It does not imply that everything listed here should be migrated.

## Security note

Shell startup files are not copied because they may contain secrets.

Review shell configuration manually before migrating anything to the new workstation.
EOF

echo
echo "Inventory successfully written to:"
echo "  $ROOT"
echo
find "$ROOT" -type f | sort