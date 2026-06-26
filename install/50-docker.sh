#!/usr/bin/env bash
set -euo pipefail

echo "Configuring Docker..."

if ! command -v docker >/dev/null 2>&1; then
    echo
    echo "ERROR: Docker CLI not found."
    echo "Install Docker Desktop via Homebrew:"
    echo
    echo "    brew install --cask docker"
    echo
    exit 1
fi

echo "Docker CLI:"
docker --version

echo

if docker info >/dev/null 2>&1; then
    echo "Docker daemon is running."
else
    echo "Docker Desktop is installed but not running."
    echo
    echo "Start Docker Desktop once and wait until it reports 'Engine running'."
fi

echo
echo "Docker configuration complete."