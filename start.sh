#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

mkdir -p ./.aws/emulator

# If a previous run left it owned by root, fix the ownership.
if [ "$(stat -c '%u' ./.aws/emulator)" -ne "$(id -u)" ]; then
  echo "Fixing ownership of ./.aws/emulator (requires sudo)..."
  sudo chown -R "$(id -u):$(id -g)" ./.aws/emulator
fi

docker-compose up -d "$@"
