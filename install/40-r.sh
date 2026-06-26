#!/usr/bin/env bash
set -euo pipefail

echo "Configuring R..."

if ! command -v R >/dev/null 2>&1; then
    echo "R not found. Install R via Brewfile first."
    exit 1
fi

echo "R:"
R --version | sed -n '1p'

echo "R configuration complete."