#!/usr/bin/env bash
# Routine deploy: sync config (incl. secrets) to the Pi and rebuild THERE.
# Use this for normal config changes (services, users, options) that DON'T rebuild
# the kernel. For kernel/nixpkgs bumps, use deploy-kernel.sh instead.
set -euo pipefail
HOST="${1:-akhil@nas}"
rsync -a \
  --exclude='.git' --exclude='.gitignore' --exclude='deploy*.sh' --exclude='README*' \
  --rsync-path="sudo rsync" \
  "$(dirname "$0")/" "$HOST:/etc/nixos/"
ssh "$HOST" 'sudo nixos-rebuild switch'
