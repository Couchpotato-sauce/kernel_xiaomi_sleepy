#!/bin/sh

# Setup the build environment
git clone --depth=1 https://github.com/akhilnarang/scripts environment
cd environment && bash setup/android_build_env.sh && cd ..

# Clone proton clang from kdrag0n's repo
git clone --depth=1 https://github.com/kdrag0n/proton-clang proton-clang

# Clone AnyKernel3
git clone --depth=1 https://github.com/Couchpotato-sauce/AnyKernel3 AnyKernel3

# Export the PATH variable
export PATH="$(pwd)/proton-clang/bin:$PATH"

# Clean up out
find out -delete
mkdir out

# Compile the kernel
build_clang() {
    make -j"$(nproc --all)" \
	O=out \
    CC="ccache clang" \
    CXX="ccache clang++" \
    AR="ccache llvm-ar" \
    AS="ccache llvm-as" \
    NM="ccache llvm-nm" \
    LD="ccache ld.lld" \
    STRIP="ccache llvm-strip" \
    OBJCOPY="ccache llvm-objcopy" \
    OBJDUMP="ccache llvm-objdump"\
    OBJSIZE="ccache llvm-size" \
    READELF="ccache llvm-readelf" \
    HOSTCC="ccache clang" \
    HOSTCXX="ccache clang++" \
    HOSTAR="ccache llvm-ar" \
    HOSTAS="ccache llvm-as" \
    HOSTNM="ccache llvm-nm" \
    HOSTLD="ccache ld.lld" \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

make O=out sleepy_defconfig
build_clang

# Zip up the kernel
zip_kernelimage() {
    rm -rf AnyKernel3/Image.gz-dtb
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
    rm -rf AnyKernel3/*.zip
    BUILD_TIME=$(date +"%d%m%Y-%H%M")
    cd AnyKernel3
    KERNEL_NAME=Sleepy-"${BUILD_TIME}"
    zip -r9 "$KERNEL_NAME".zip ./*
    cd ..
}

FILE="$(pwd)/out/arch/arm64/boot/Image.gz-dtb"
if [ -f "$FILE" ]; then
    zip_kernelimage
    echo "The kernel has successfully been compiled and can be found in $(pwd)/AnyKernel3/"$KERNEL_NAME".zip"
    FILE_CI="/drone/src/AnyKernel3/"$KERNEL_NAME".zip"
    if [ -f "$FILE_CI" ]; then
        curl --connect-timeout 10 -T "$FILE_CI" https://oshi.at
        curl --connect-timeout 10 --upload-file "$FILE_CI" https://transfer.sh
        echo " "
    fi
else
    echo "The kernel has failed to compile. Please check the terminal output for further details."
    exit 1
fi
