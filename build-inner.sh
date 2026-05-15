#!/bin/bash
# Container-side build script for Tina Linux / Moss Zero28 firmware.
# Executed non-interactively by rebuild.sh, but can also be run directly
# inside an interactive container session for debugging.

set -e

# Print the failing command on any error so build failures are diagnosable.
trap 'echo "[build-inner.sh] FAILED at line $LINENO: $BASH_COMMAND" >&2' ERR

cd /root/lichee

# 'source' is required here because lunch, add-rootfs-demo, and pack are
# shell functions defined by envsetup.sh, not standalone executables.
# bash -i (set by rebuild.sh) is required so envsetup.sh sees an interactive
# shell and defines those functions — it guards them with [[ $- == *i* ]].
source build/envsetup.sh

# Numeric arg selects board non-interactively (item 3 = a133_aw3-tina).
lunch 3

export PATH="/root/lichee/lichee/arisc/ar100s/tools/toolchain/bin:$PATH"

cp /root/workspace/assets/configs/phase3-complete.config .config

bash /root/workspace/assets/install.sh

yes '' | make oldconfig

bash /root/workspace/assets/set-config.sh

make -j$(nproc)

add-rootfs-demo && pack
