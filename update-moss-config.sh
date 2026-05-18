#!/bin/bash
# Host-side utility to update configs/moss-tina.config from the live SDK .config.
# Run from the host after editing the kernel config inside the container
# (e.g. via make menuconfig).
#
# Usage: ./update-moss-config.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK="/home/thwonp/Downloads/Zero 28 Linux_SDK/Stock SDK/lichee"
LOCAL_CONFIG="$SDK/.config"
REPO_CONFIG="$SCRIPT_DIR/configs/moss-tina.config"
BACKUP_DIR="$SCRIPT_DIR/configs/backups"

if [ ! -f "$LOCAL_CONFIG" ]; then
    echo "Error: $LOCAL_CONFIG not found — run build-inner.sh first." >&2
    exit 1
fi

if [ ! -f "$REPO_CONFIG" ]; then
    echo "Error: $REPO_CONFIG not found." >&2
    exit 1
fi

echo "--- Diff (repo vs live .config) ---"
diff "$REPO_CONFIG" "$LOCAL_CONFIG" || true
echo "--- End diff ---"
echo ""

CHANGED=$(diff "$REPO_CONFIG" "$LOCAL_CONFIG" | grep -c '^[<>]' || true)
echo "Changed lines: $CHANGED"

if [ "$CHANGED" -eq 0 ]; then
    echo "No differences — moss-tina.config is already up to date."
    exit 0
fi

echo ""
read -rp "Apply current .config as new moss-tina.config? [y/N] " answer
if [[ ! "$answer" =~ ^[yY]$ ]]; then
    echo "Aborted."
    exit 0
fi

mkdir -p "$BACKUP_DIR"
BACKUP_PATH="$BACKUP_DIR/moss-tina.config.$(date +%Y%m%d-%H%M%S)"
cp "$REPO_CONFIG" "$BACKUP_PATH"
cp "$LOCAL_CONFIG" "$REPO_CONFIG"

echo "Backup saved to: $BACKUP_PATH"
echo "moss-tina.config updated."
