#!/bin/bash
# Container-side build script for Tina Linux / Moss Zero28 firmware.
#
# IMPORTANT: Source this script, do not run it with bash.
# bash creates a subshell that cannot inherit shell functions from the parent.
#
# Required setup before sourcing:
#   cd /root/lichee
#   source build/envsetup.sh
#   lunch                    # select 3 (a133_aw3-tina)
#
# Then run:
#   . /root/workspace/assets/build-inner.sh
#
# The body runs inside a subshell ( ) so set -e failures exit only the build,
# not your interactive container session.

(
set -e
trap 'echo "[build-inner.sh] FAILED at line $LINENO: $BASH_COMMAND" >&2' ERR

cd /root/lichee

# Verify lunch was run before sourcing this script.
for fn in add-rootfs-demo pack; do
    if ! type "$fn" &>/dev/null; then
        echo "[build-inner.sh] ERROR: '$fn' not defined." >&2
        echo "  Run first: source build/envsetup.sh && lunch (select 3)" >&2
        exit 1
    fi
done
echo "[build-inner.sh] Build environment OK (lunch already run)"

export PATH="/root/lichee/lichee/arisc/ar100s/tools/toolchain/bin:$PATH"

echo "[build-inner.sh] Copying phase3-complete.config to .config ..."
cp /root/workspace/assets/configs/phase3-complete.config .config
echo "[build-inner.sh] Config copied — $(wc -l < .config) lines"

echo "[build-inner.sh] Running install.sh ..."
bash /root/workspace/assets/install.sh

echo "[build-inner.sh] Verifying board defconfig toolchain patch ..."
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
)
