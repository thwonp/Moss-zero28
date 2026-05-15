#!/bin/bash
# Container-side build script for Tina Linux / Moss Zero28 firmware.
# Run from inside the container: bash /root/workspace/assets/build-inner.sh

set -e

cd /root/lichee

# lunch, add-rootfs-demo, and pack are shell functions defined by envsetup.sh.
# envsetup.sh may reset traps; ERR trap is set after sourcing.
source build/envsetup.sh
trap 'echo "[build-inner.sh] FAILED at line $LINENO: $BASH_COMMAND" >&2' ERR

if ! type lunch &>/dev/null; then
    echo "[build-inner.sh] ERROR: 'lunch' not defined after sourcing envsetup.sh." >&2
    echo "  Run manually: source build/envsetup.sh && lunch (select 3), then re-run this script." >&2
    exit 1
fi

# Numeric arg selects board target; 3 = a133_aw3-tina. Prompts if arg not accepted.
lunch 3

if ! type add-rootfs-demo &>/dev/null; then
    echo "[build-inner.sh] ERROR: 'add-rootfs-demo' not defined — lunch did not complete." >&2
    exit 1
fi
echo "[build-inner.sh] lunch OK (add-rootfs-demo available)"

export PATH="/root/lichee/lichee/arisc/ar100s/tools/toolchain/bin:$PATH"

echo "[build-inner.sh] Copying phase3-complete.config to .config ..."
cp /root/workspace/assets/configs/phase3-complete.config .config
echo "[build-inner.sh] Config copied — $(wc -l < .config) lines"

echo "[build-inner.sh] Running install.sh ..."
bash /root/workspace/assets/install.sh

echo "[build-inner.sh] Verifying board defconfig patch (GCC version) ..."
grep 'CONFIG_GCC_VERSION=' /root/lichee/target/allwinner/a133-aw3/defconfig | head -1

echo "[build-inner.sh] Running make oldconfig ..."
yes '' | make oldconfig

echo "[build-inner.sh] Running set-config.sh ..."
bash /root/workspace/assets/set-config.sh

echo "[build-inner.sh] Verifying toolchain in .config after set-config ..."
grep 'CONFIG_GCC_VERSION=' .config | head -1

echo "[build-inner.sh] Starting build ..."
make -j$(nproc)

add-rootfs-demo && pack
