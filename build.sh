#!/bin/bash

# Kernel Build Script for Local Environment
# Adapted from GitHub Action workflow (Deepseek)

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Append Clean and Setup into one step

print_info "设置编译环境和清理编译环境..."
TC_DIR="$HOME/toolchains"
CLANG_BIN_DIR="$TC_DIR/clang/host/linux-x86/clang-r346389c/bin"
GCC_64_BIN_DIR="$TC_DIR/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin"
GCC_32_BIN_DIR="$TC_DIR/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin"

export CLANG_PREBUILTS_PATH=$TC_DIR/clang/host/linux-x86/clang-r346389c/
export LD_LIBRARY_PATH=$TC_DIR/clang/host/linux-x86/clang-r346389c/lib64:$LD_LIBRARY_PATH
export PATH="$CLANG_BIN_DIR:$GCC_64_BIN_DIR:$GCC_32_BIN_DIR:$PATH"

export ARCH=arm64
export CROSS_COMPILE=$GCC_64_BIN_DIR/aarch64-linux-androidkernel-
export CROSS_COMPILE_ARM32=$GCC_32_BIN_DIR/arm-linux-androideabi-
export CLANG_TRIPLE=aarch64-linux-gnu-

export TARGET_BUILD_VARIANT=user

sudo ln -sf /usr/bin/python2.7 /usr/bin/python  

rm -rf out && mkdir -p out
rm -rf build_kernel.log

print_info "环境变量设置完成"

print_info "配置内核..."

# Continue to build anyway (-k)
make -j$(nproc --all) O=out CC=clang LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy \
    merge_full_k6853v1_64_defconfig

print_info "内核配置完成"

print_info "开始编译内核..."

make -j$(nproc --all) O=out CC=clang LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy \
    $@ \
    Image.gz dtbs 2>&1 | tee -a build_kernel.log

if [ -f "out/arch/arm64/boot/Image.gz" ]; then
    print_info "Image.gz 编译成功!"
    ls -lh "out/arch/arm64/boot/Image.gz"
    file "out/arch/arm64/boot/Image.gz"
else
    print_error "内核编译失败!"
fi