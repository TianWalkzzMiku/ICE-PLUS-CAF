#!/usr/bin/env bash
# Copyright (C) 2021-2022 Oktapra Amtono <oktapra.amtono@gmail.com>
# Kernel Build Script

# Kernel directory
KERNEL_DIR=$PWD

# Start counting
BUILD_START=$(date +"%s")

# Name and version of kernel
KERNEL_NAME="Ice+-OSS"
KERNEL_VERSION="Aqua"

# Device name
if [[ "$*" =~ "a26x" ]]; then
    DEVICE="a26x"
    export LOCALVERSION="_$KERNEL_VERSION"
elif [[ "$*" =~ "lavender" ]]; then
    DEVICE="lavender"
    export LOCALVERSION="_$KERNEL_VERSION"
elif [[ "$*" =~ "tulip" ]]; then
    DEVICE="tulip"
    export LOCALVERSION="_$KERNEL_VERSION"
elif [[ "$*" =~ "whyred" ]]; then
    DEVICE="whyred"
    export LOCALVERSION="_$KERNEL_VERSION"
fi

# Blob version
if [[ "$*" =~ "newcam" ]]; then
    CONFIGVERSION="newcam"
elif [[ "$*" =~ "oldcam" ]]; then
    CONFIGVERSION="oldcam"
elif [[ "$*" =~ "tencam" ]]; then
    CONFIGVERSION="tencam"
elif [[ "$*" =~ "qtihaptics" ]]; then
    CONFIGVERSION="qtihaptics"
fi

# Export localversion for OC variant
if [[ "$*" =~ "oc" ]]; then
    export LOCALVERSION="_$KERNEL_VERSION-OC"
fi

# Setup environtment
export CHAT_ID
export BOT_TOKEN
export ARCH=arm64
export SUBARCH=arm64
export CLANG_PATH="$KERNEL_DIR/clang/bin:$CLANG_PATH"
export KBUILD_BUILD_USER="Tiann"
export KBUILD_BUILD_HOST="IcePrjkt"
AK3_DIR=$KERNEL_DIR/ak3-$DEVICE
KERNEL_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz
ZIP_NAME="$KERNEL_NAME"_"$DEVICE""$LOCALVERSION"_"$CONFIGVERSION".zip

# Setup toolchain
if [[ "$*" =~ "clang" ]]; then
    CLANG_DIR="$KERNEL_DIR/clang"
    export PATH="$KERNEL_DIR/clang/bin:$PATH"
    CLGV="$("$CLANG_DIR"/bin/clang --version | head -n 1)"
    BINV="$("$CLANG_DIR"/bin/ld --version | head -n 1)"
    LLDV="$("$CLANG_DIR"/bin/ld.lld --version | head -n 1)"
    export KBUILD_COMPILER_STRING="$CLGV - $BINV - $LLDV"
elif [[ "$*" =~ "gcc" ]]; then
    GCC_DIR="$KERNEL_DIR/arm64"
    GCCV="$("$GCC_DIR"/bin/aarch64-elf-gcc --version | head -n 1)"
    BINV="$("$GCC_DIR"/bin/aarch64-elf-ld --version | head -n 1)"
    LLDV="$("$GCC_DIR"/bin/aarch64-elf-ld.lld --version | head -n 1)"
    export KBUILD_COMPILER_STRING="$GCCV - $BINV - $LLDV"
fi

# Telegram setup
push_message() {
    curl -s -X POST \
        https://api.telegram.org/bot"{$BOT_TOKEN}"/sendMessage \
        -d chat_id="${CHAT_ID}" \
        -d text="$1" \
        -d "parse_mode=html" \
        -d "disable_web_page_preview=true"
}

push_document() {
    curl -s -X POST \
        https://api.telegram.org/bot"{$BOT_TOKEN}"/sendDocument \
        -F chat_id="${CHAT_ID}" \
        -F document=@"$1" \
        -F caption="$2" \
        -F "parse_mode=html" \
        -F "disable_web_page_preview=true"
}

# Export defconfig
make O=out ice-"$DEVICE"-"$CONFIGVERSION"_defconfig

# Enable QTI haptics for all build
scripts/config --file out/.config -e CONFIG_INPUT_QTI_HAPTICS

# Start compile
        CC="$CLANG_PATH/clang" \
        AR="$CLANG_PATH/llvm-ar" \
        OBJDUMP="$CLANG_PATH/llvm-objdump" \

    export CROSS_COMPILE="$KERNEL_DIR/arm64/bin/aarch64-none-linux-gnu-"
    export CROSS_COMPILE_ARM32="$KERNEL_DIR/arm32/bin/arm-none-eabi-"
    make -j"$(nproc --all)" O=out ARCH=arm64

# Push message if build error
if ! [ -a "$KERNEL_IMG" ]; then
    push_message "<b>Failed building kernel for <code>$DEVICE-$CONFIGVERSION</code> Please fix it...!</b>"
    exit 1
fi

# Make zip
cp -r "$KERNEL_IMG" "$AK3_DIR"/kernel/
cd "$AK3_DIR" || exit
zip -r9 "$ZIP_NAME" ./*
cd "$KERNEL_DIR" || exit
cp "$AK3_DIR"/*.zip kernel-done/

# End count and calculate total build time
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

# Push kernel to telegram
push_document "$AK3_DIR/$ZIP_NAME" "
<b>device :</b> <code>$DEVICE</code>
<b>kernel version :</b> <code>$KERNEL_VERSION</code>
<b>blob version :</b> <code>$CONFIGVERSION</code>
<b>md5 checksum :</b> <code>$(md5sum "$AK3_DIR/$ZIP_NAME" | cut -d' ' -f1)</code>
<b>build time :</b> <code>$(("$DIFF" / 60)) minute, $(("$DIFF" % 60)) second</code>"

rm -rf out/arch/arm64/boot/
rm -rf out/.version
rm -rf "$AK3_DIR"/*.zip
