#!/bin/bash

# 1. Toolchain and Environment Configuration (Physwizz Repo Paths)
export CROSS_COMPILE=$(pwd)/toolchain/toolchains-gcc-10.3.0/bin/aarch64-buildroot-linux-gnu-
export CC=$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y
export CONFIG_DRV_BUILD_IN=y

# Ensure the output build directory exists
mkdir -p $(pwd)/out

echo "=== [1/6] Generating base defconfig ==="
make -C $(pwd) O=$(pwd)/out a13ve_defconfig

echo "=== [2/6] Force-merging config fragments ==="
# This physically appends your custom configs to the bottom of the active config
cat droidspaces.config scamsung.config droidspaces_opt.config ksu.config >> $(pwd)/out/.config

echo "=== [3/6] Validating final configuration ==="
# This forces the kernel to read the appended configs, resolve dependencies, and lock them in
make -C $(pwd) O=$(pwd)/out olddefconfig

echo "=== [4/6] Cleaning build directory ==="
make -C $(pwd) O=$(pwd)/out clean

echo "=== [5/6] Starting compilation ==="
make -C $(pwd) O=$(pwd)/out -j$(nproc)

echo "=== [6/6] Copying final kernel Image ==="
cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image

echo "=== Build Process Finished! ==="
