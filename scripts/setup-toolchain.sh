#!/usr/bin/env bash
set -e

: "${WORK_DIR:=$GITHUB_WORKSPACE}"

CLANG_VER="neutron-clang-06092026"
CLANG_URL="https://github.com/Neutron-Toolchains/clang-build-catalogue/releases/download/06092026/${CLANG_VER}.tar.zst"
CLANG_ARCHIVE="/tmp/${CLANG_VER}.tar.zst"
CLANG_DIR="${WORK_DIR}/prebuilts/clang/host/linux-x86/${CLANG_VER}"

mkdir -p "$CLANG_DIR"
aria2c -x16 -s16 -d "$(dirname "$CLANG_ARCHIVE")" -o "$(basename "$CLANG_ARCHIVE")" "$CLANG_URL"
tar --zstd -xf "$CLANG_ARCHIVE" -C "$CLANG_DIR"
rm -f "$CLANG_ARCHIVE"

test -x "$CLANG_DIR/bin/clang"

echo "CLANG_DIR=$CLANG_DIR" >> "${GITHUB_ENV:-/dev/null}"
echo "[OK] Toolchain ready: $CLANG_DIR"
