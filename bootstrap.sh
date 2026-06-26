#!/usr/bin/env bash
set -euo pipefail

echo "Workstation Bootstrap"
echo "====================="
echo

./install/10-homebrew.sh
./install/20-brewfile.sh
./install/30-python.sh
./doctor.sh

echo
echo "Bootstrap completed."