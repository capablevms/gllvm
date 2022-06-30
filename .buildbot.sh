#!/usr/bin/env bash
# Build and extract bitcode from lua cross-compiling to CHERI
# riscv64-purecap and morello-purecap

set -e

ARCH=
CHERI=
CONFIG_FLAGS=

if [ "$1" = "morello-purecap" ]; then
	ARCH="morello"
	CHERI=$HOME/cheri/output/"$ARCH"-sdk
	CONFIG_FLAGS="-target aarch64-unknown-freebsd13 \
	  --sysroot=${HOME}/cheri/output/rootfs-morello-purecap \
	  -B${HOME}/cheri/output/morello-sdk/bin \
	  -mcpu=rainier -march=morello+c64 -mabi=purecap"
elif [ "$1" = "riscv64-purecap" ]; then
	ARCH="riscv64"
	CHERI=$HOME/cheri/output/sdk
	CONFIG_FLAGS="-target riscv64-unknown-freebsd13 \
	  --sysroot=${HOME}/cheri/output/rootfs-riscv64-purecap \
	  -B${HOME}/output/sdk/bin -march=rv64imafdcxcheri \
	  -mabi=l64pc128d -mno-relax"
else
	echo "Only purecap architectures, i.e. riscv64 and morello, are supported."
	# Exit gracefully because we do not want the build to fail
	exit 0
fi

LLVM_COMPILER_PATH=$CHERI/bin
CC=$LLVM_COMPILER_PATH/clang
GLLVM_OBJCOPY=$LLVM_COMPILER_PATH/objcopy
AR=$LLVM_COMPILER_PATH/llvm-ar
RANLIB=$LLVM_COMPILER_PATH/llvm-ranlib

go build -v ./...
go install -v ./...
GCLANG=$HOME/go/bin/gclang
GET_BC=$HOME/go/bin/get-bc

tmpdir=/tmp/lua-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)/
mkdir -p $tmpdir

cd $tmpdir
	git clone --depth 1 -b v5.4.0 https://github.com/lua/lua.git .
	sed -i 's/-march=native//g' makefile
	make CC=$GCLANG LLVM_COMPILER_PATH=$LLVM_COMPILER_PATH GLLVM_OBJCOPY=$GLLVM_OBJCOPY MYCFLAGS="-std=c99 $CONFIG_FLAGS" MYLDFLAGS="$CONFIG_FLAGS -Wl,-E -Wl,-v" AR="$AR rc" RANLIB=$RANLIB MYLIBS=" -ldl" -j 16
	LLVM_COMPILER_PATH=$LLVM_COMPILER_PATH $GET_BC lua