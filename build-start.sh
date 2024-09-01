#!/usr/bin/env bash
# Copyright (C) 2020-2022 Oktapra Amtono <oktapra.amtono@gmail.com>
# Docker Kernel Build Script

# Clone kernel source
if [[ "$*" =~ "stable" ]]; then
    git clone --depth=1 https://github.com/TianWalkzzMiku/ICE-PLUS-CAF.git -b caf kernel
    cd kernel || exit
fi

# Clone toolchain
if [[ "$*" =~ "clang" ]]; then
    git clone --depth=1 https://github.com/bibi09456/sdclang clang
elif [[ "$*" =~ "gcc" ]]; then
    git clone --depth=1 ttps://github.com/Project-1CE/prebuilts_gcc_linux-x86_arm_arm-none-eabi arm32
    git clone --depth=1 ttps://github.com/Project-1CE/prebuilts_gcc_linux-x86_arm_arm-none-eabi arm64
fi

# Clone anykernel3
git clone --depth=1 https://github.com/TianWalkzzMiku/AK3-4.4.git -b lavender-dtb ak3-lavender
git clone --depth=1 https://github.com/TianWalkzzMiku/AK3-4.4.git -b whyred-dtb ak3-whyred
git clone --depth=1 https://github.com/TianWalkzzMiku/AK3-4.4.git -b tulip-dtb ak3-tulip
git clone --depth=1 https://github.com/TianWalkzzMiku/AK3-4.4.git -b a26x-dtb ak3-a26x

# Telegram setup
push_message() {
    curl -s -X POST \
        https://api.telegram.org/bot"{$BOT_TOKEN}"/sendMessage \
        -d chat_id="${CHAT_ID}" \
        -d text="$1" \
        -d "parse_mode=html" \
        -d "disable_web_page_preview=true"
}

# Push message to telegram
push_message "
<b>======================================</b>
<b>Start Building :</b> <code>Ice+ Kernel</code>
<b>Linux Version :</b> <code>$(make kernelversion | cut -d " " -f5 | tr -d '\n')</code>
<b>Source Branch :</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>
<b>======================================</b> "