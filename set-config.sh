#!/bin/bash
# Overlays phase3-complete.config onto the normalized .config.
# Run AFTER "yes '' | make oldconfig" and BEFORE "make -j8".
# Applies every setting from the saved config, overwriting whatever normalization reset.

set -e
CONFIG="/root/lichee/.config"
DESIRED="/root/workspace/assets/configs/phase3-complete.config"

[ -f "$CONFIG" ] || { echo "Error: $CONFIG not found. Run 'yes \"\" | make oldconfig' first." >&2; exit 1; }
[ -f "$DESIRED" ] || { echo "Error: $DESIRED not found." >&2; exit 1; }

# Build a sed script to remove all keys present in DESIRED from the normalized .config.
# One pass for performance (avoids running sed once per line on a large file).
TMPSCRIPT=$(mktemp)

while IFS= read -r line; do
    if [[ "$line" =~ ^(CONFIG_[^=]+)= ]]; then
        key="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^#\ (CONFIG_[^[:space:]]+)\ is\ not\ set ]]; then
        key="${BASH_REMATCH[1]}"
    else
        continue
    fi
    printf '/^%s=/d\n/^# %s is not set$/d\n' "$key" "$key"
done < "$DESIRED" > "$TMPSCRIPT"

sed -i -f "$TMPSCRIPT" "$CONFIG"
rm "$TMPSCRIPT"

# Append all desired settings.
grep -E '^(CONFIG_|# CONFIG_)' "$DESIRED" >> "$CONFIG"

echo "Config overlay applied ($(grep -cE '^(CONFIG_|# CONFIG_)' "$DESIRED") settings)."
echo "Run: make -j8 && add-rootfs-demo && pack"
