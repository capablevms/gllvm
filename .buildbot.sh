#!/usr/bin/env bash
# Build and extract bitcode from sqlite3 cross-compiling to CHERI
# riscv64-purecap

set -e

if ! [ "$1" = "riscv64" ]; then
	echo "Only riscv64 is supported."
	# Exit gracefully because we do not want the build to fail
	exit 0
fi

CHERI=$HOME/cheri/output/sdk
CHERIBUILD=$HOME/build
CC=$CHERI/bin/clang
LLVM_COMPILER_PATH=$CHERI/bin
GLLVM_OBJCOPY=$LLVM_COMPILER_PATH/objcopy
SQLITE_DIR=$HOME/cheri/build/sqlite-riscv64-purecap-build

go build -v ./...
go install -v ./...
GCLANG=$HOME/go/bin/gclang
GET_BC=$HOME/go/bin/get-bc

cd $CHERIBUILD
python3 cheribuild.py sqlite-riscv64-purecap
cd $SQLITE_DIR
make clean
sed -i "s|$CC|$GCLANG|g" Makefile
LLVM_COMPILER_PATH=$LLVM_COMPILER_PATH GCLANG=$GCLANG GLLVM_OBJCOPY=$GLLVM_OBJCOPY make
LLVM_COMPILER_PATH=$LLVM_COMPILER_PATH $GET_BC sqlite3