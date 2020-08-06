#!/bin/sh

# Copyright (C) 2020 Lacia chan / Lyceris chan <ghostdrain@outlook.com>
# Copyright (C) 2018 Harsh 'MSF Jarvis' Shandilya
# Copyright (C) 2018 Akhil Narang
# SPDX-License-Identifier: GPL-3.0-only

# Setup compile enviroment
FILE="cscripts/README.md"
if [ -f "$FILE" ]; then
    cd cscripts || exit
    sh ./proton-clang.sh
    cd ..
else
    git clone https://github.com/Daisy-Q-sources/scripts cscripts
    cd cscripts || exit
    sh ./setup_env.sh
    cd ..
fi

# Incremental releases go brr
FILE="incremental/value.dat"
if [ -f "$FILE" ]; then
    # Read the value from the file
    value=$(cat incremental/value.dat)

    # increment the value
    value=$((value + 1))

    # and save it for next time
    echo "${value}" >incremental/value.dat

    # push to git
    cd incremental || exit
    git add .
    git commit -m +1
    git push
    cd ..

else

    git clone https://github.com/Lyceris-chan/incremental_release incremental

    # Read the value from the file
    value=$(cat incremental/value.dat)

    # increment the value
    value=$((value + 1))

    # and save it for next time
    echo "${value}" >incremental/value.dat

    # push to git
    cd incremental || exit
    git add .
    git commit -m +1
    git push
    cd ..
fi

# Main variables
CORES=$(grep -c ^processor /proc/cpuinfo)
BUILD_START=$(date +"%s")
DATE=$(date)
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"
export PATH="$(pwd)/proton-clang/bin:$PATH"
export KBUILD_COMPILER_STRING="$($(pwd)/proton-clang/bin/clang --version | head -n 1 | perl -pe 's/\((?:http|git).*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
RELEASE=$(cat incremental/value.dat)

# Clone private repo with the $BOTTOKEN and $CHATID
FILE="$(pwd)/bapi/bottoken.txt"
if [ -f "$FILE" ]; then

    # Export the BOTTOKEN and CHATID from my private repository
    BOTTOKEN="$(sed 's/BOTTOKEN = //g' $(pwd)/bapi/bottoken.txt)"
    CHATID="$(sed 's/CHATID = //g' $(pwd)/bapi/chatid.txt)"

else

    # Clone my private repository for the CHATID and BOTTOKEN
    git clone https://github.com/Lyceris-chan/telegram_bot_api_stuff bapi

    # Export the BOTTOKEN and CHATID from my private repository
    BOTTOKEN="$(sed 's/BOTTOKEN = //g' $(pwd)/bapi/bottoken.txt)"
    CHATID="$(sed 's/CHATID = //g' $(pwd)/bapi/chatid.txt)"
fi

# Figure out the localversion
rm -rf localv.txt
grep "SUBLEVEL =" Makefile >localv.txt
SUBLVL="$(sed 's/SUBLEVEL = //g' localv.txt)"
LOCALV=4.9.$SUBLVL

# Clean up out
rm -rf out/*

# Post build compilation information in $CHATID
curl -s -X POST "https://api.telegram.org/bot$BOTTOKEN/sendMessage" -d chat_id="-$CHATID" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=markdown" \
    -d text="⚙️Build for \`Daisy / Sakura (non SAR)\` started at \`$DATE\` using \`$CORES\` threads.

Compiler: \`$KBUILD_COMPILER_STRING\`
Localversion: \`$LOCALV\`

Release: \`r$RELEASE\`

Branch: \`$PARSE_BRANCH\`
Commit: \`$COMMIT_POINT\`


Kernel: \`Sleepy\`"

# Compile the kernel
build_clang() {
    make -j$(nproc --all) O=out \
        ARCH=arm64 \
        CC=clang \
        AR="llvm-ar" \
        NM="llvm-nm" \
        OBJCOPY="llvm-objcopy" \
        OBJDUMP="llvm-objdump" \
        STRIP="llvm-strip" \
        CROSS_COMPILE=aarch64-linux-gnu-
}

make O=out ARCH=arm64 sleepy_defconfig
build_clang

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

# Post failure in channel

FILE="$(pwd)/out/arch/arm64/boot/Image.gz-dtb"
if [ -f "$FILE" ]; then

    # Zip it
    rm -rf $(pwd)/AnyKernel3/Image.gz-dtb
    cp $(pwd)/out/arch/arm64/boot/Image.gz-dtb AnyKernel3
    rm -rf $(pwd)/AnyKernel3/*.zip
    BUILD_TIME=$(date +"%d%m%Y-%H%M")
    cd AnyKernel3 || exit
    zip -r9 Sleepy-r"${RELEASE}"-"${BUILD_TIME}".zip *
    cd ..

    # Post release in channel
    curl -F document=@"$(pwd)/AnyKernel3/Sleepy-r${RELEASE}-${BUILD_TIME}.zip" "https://api.telegram.org/bot$BOTTOKEN/sendDocument" \
        -F chat_id="-$CHATID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=Markdown" \
        -F caption="✅ Build finished in \`$(($DIFF / 60))\` minute(s) and \`$(($DIFF % 60))\` seconds"
else

    curl -s -X POST "https://api.telegram.org/bot$BOTTOKEN/sendMessage" -d chat_id="-$CHATID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="❌ Build failed in \`$(($DIFF / 60))\` minute(s) and \`$(($DIFF % 60))\` seconds check you're terminal"

fi
