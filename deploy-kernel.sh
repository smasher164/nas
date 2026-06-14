#!/usr/bin/env bash
# Kernel / big deploy: build on the Mac (M5 linux-builder), copy the closure to the
# Pi as root (the Pi rejects unsigned paths from a non-trusted user), set it as the
# boot generation, then YOU reboot the Pi (physical access — it's headless).
# Requires the nix-darwin linux-builder (ephemeral, 4 cores, 64G disk) to be enabled.
set -euo pipefail
HOST="${1:-akhil@nas}"
DIR="$(cd "$(dirname "$0")" && pwd)"

# 'path:' (not the bare path) so git-ignored secrets like wifi.nix are included in the build.
echo "Building on the Mac linux-builder..."
TOP=$(nix build --no-link --print-out-paths \
  "path:$DIR#nixosConfigurations.nas.config.system.build.toplevel")
echo "Built: $TOP"

echo "Importing missing paths to the Pi as root..."
nix-store -qR "$TOP" | ssh "$HOST" 'while read p; do [ -e "$p" ] || echo "$p"; done' > /tmp/nas-missing.txt
echo "  ($(wc -l < /tmp/nas-missing.txt) paths to send)"
nix-store --export $(cat /tmp/nas-missing.txt) | ssh "$HOST" 'sudo nix-store --import' >/dev/null

echo "Setting as boot generation (no activation)..."
ssh "$HOST" "sudo nix-env -p /nix/var/nix/profiles/system --set $TOP && sudo $TOP/bin/switch-to-configuration boot"

echo
echo "DONE. New system staged as boot default. Reboot the Pi (be at the hardware): ssh $HOST 'sudo reboot'"
