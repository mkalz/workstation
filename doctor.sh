#!/usr/bin/env bash
set -euo pipefail

PASS="✅"
WARN="⚠️"
FAIL="❌"

check() {
    local cmd="$1"

    if command -v "$cmd" >/dev/null 2>&1; then
        printf "%s %s\n" "$PASS" "$cmd"
    else
        printf "%s %s\n" "$FAIL" "$cmd"
    fi
}

echo
echo "Workstation Doctor"
echo "=================="
echo

check brew
check git
check gh
check python3
check uv
check R
check quarto
check hugo
check node
check go

if docker info >/dev/null 2>&1; then
    echo "$PASS Docker daemon"
else
    echo "$WARN Docker daemon not running"
fi

echo
echo "Python:"
python3 --version || true

echo
echo "uv:"
uv --version || true

echo
echo "Git:"
git --version

echo
echo "Homebrew:"
brew --version | sed -n '1p'

echo
echo "Doctor completed."