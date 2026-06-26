#!/usr/bin/env bash
set -euo pipefail

echo "Workstation Bootstrap"
echo "====================="
echo

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found."
    echo "Install Homebrew first from https://brew.sh/ and rerun this script."
    exit 1
fi

echo "Updating Homebrew..."
brew update

echo
echo "Installing Brewfile..."
brew bundle install --file Brewfile

echo
echo "Running doctor..."
./doctor.sh

echo
echo "Bootstrap completed."