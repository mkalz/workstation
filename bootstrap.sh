#!/usr/bin/env bash
set -euo pipefail

echo "Workstation Bootstrap"
echo "====================="
echo

./install/homebrew.sh
./install/brewfile.sh
./doctor.sh

echo
echo "Bootstrap completed."