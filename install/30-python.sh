#!/usr/bin/env bash
set -euo pipefail

echo "Configuring Python..."

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found. Install Python via Brewfile first."
    exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "uv not found. Install uv via Brewfile first."
    exit 1
fi

echo "Python:"
python3 --version

echo "uv:"
uv --version

echo "Python configuration complete."