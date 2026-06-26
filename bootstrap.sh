#!/usr/bin/env bash
set -euo pipefail

echo "Workstation Bootstrap"
echo "====================="
echo

./install/10-homebrew.sh
./install/20-brewfile.sh
./doctor.sh

echo
echo "Bootstrap completed."