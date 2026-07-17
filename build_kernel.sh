#!/bin/bash

# 1. Toolchain and Environment Configuration (Physwizz Repo Paths)
export CROSS_COMPILE=$(pwd)/toolchain/toolchains-gcc-10.3.0/bin/aarch64-buildroot-linux-gnu-
export CC=$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y
export CONFIG_DRV_BUILD_IN=y

# Helper tool paths
STRIP_TOOL=$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/llvm-strip

# Ensure build directories exist
mkdir -p $(pwd)/out
mkdir -p $(pwd)/out/modules_dist
mkdir -p $(pwd)/out/modules_flat

echo "=== [1/7] Generating base defconfig ==="
make -C $(pwd) O=$(pwd)/out a13ve_defconfig

echo "=== [2/7] Force-merging config fragments ==="
cat arch/arm64/configs/droidspaces.config \
    arch/arm64/configs/scamsung.config \
    arch/arm64/configs/droidspaces_opt.config \
    arch/arm64/configs/ksu.config >> $(pwd)/out/.config

echo "=== [3/7] Validating final configuration ==="
make -C $(pwd) O=$(pwd)/out olddefconfig

echo "=== [4/7] Cleaning build directory ==="
make -C $(pwd) O=$(pwd)/out clean
rm -rf $(pwd)/out/modules_dist/*
rm -rf $(pwd)/out/modules_flat/*

echo "=== [5/7] Starting compilation (Kernel Image & Modules) ==="
# This compiles both the Image and all configured .ko modules
make -C $(pwd) O=$(pwd)/out -j$(nproc)

echo "=== [6/7] Extracting, Stripping, and Organizing Modules ==="
# 1. Install all compiled modules to our temporary staging directory
make -C $(pwd) O=$(pwd)/out INSTALL_MOD_PATH=$(pwd)/out/modules_dist modules_install

# 2. Find all generated .ko modules and strip debug symbols to make them small/loadable
echo "Stripping modules..."
find $(pwd)/out/modules_dist -name "*.ko" -exec $STRIP_TOOL --strip-unneeded {} +

# 3. Copy all stripped modules into a clean, single folder for easy retrieval
echo "Collecting modules..."
find $(pwd)/out/modules_dist -name "*.ko" -exec cp {} $(pwd)/out/modules_flat/ \;

echo "=== [7/7] Copying final kernel Image ==="
cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image

echo "=== Build Process Finished Successfully! ==="
echo "Your built kernel is at: $(pwd)/arch/arm64/boot/Image"
echo "Your compiled modules are waiting for you in: $(pwd)/out/modules_flat/"
