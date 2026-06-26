#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found."
    echo "Install Homebrew from https://brew.sh/ and rerun bootstrap."
    exit 1
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

brew update