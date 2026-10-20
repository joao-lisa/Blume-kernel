#!/usr/bin/env bash
set -e

: "${SOURCE_TYPE:?}"
: "${KERNEL_SRC:?}"
: "${WORK_DIR:?}"
: "${DEFCONFIG:?}"
: "${CLANG_DIR:?}"

OUT_DIR="${WORK_DIR}/out"
START=$(date +%s)

export KBUILD_BUILD_USER="${KBUILD_BUILD_USER:-joao-lisa}"
export KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST:-github}"
export PATH="${CLANG_DIR}/bin:$PATH"

if command -v ccache &>/dev/null; then _CC="ccache clang"; else _CC="clang"; fi

MAKE_FLAGS=(
  -j$(nproc)
  O="${OUT_DIR}/dist"
  ARCH=arm64
  SUBARCH=arm64
  LLVM=1
  LLVM_IAS=1
  CC="$_CC"
  LD=ld.lld
  AR=llvm-ar
  NM=llvm-nm
  OBJCOPY=llvm-objcopy
  OBJDUMP=llvm-objdump
  STRIP=llvm-strip
  OBJSIZE=llvm-size
  READELF=llvm-readelf
  CROSS_COMPILE=aarch64-linux-gnu-
  CROSS_COMPILE_ARM32=arm-linux-gnueabi-
  KBUILD_BUILD_USER="$KBUILD_BUILD_USER"
  KBUILD_BUILD_HOST="$KBUILD_BUILD_HOST"
  KCFLAGS="-pipe -fno-strict-aliasing -fno-common -Wno-error -Wno-unknown-warning-option -Wno-array-bounds -Wno-stringop-overflow -Wno-mismatched-function-types -Wno-unused-variable -Wno-misleading-indentation -Wno-incompatible-function-pointer-types"
  LLVM_PARALLEL_LINK_JOBS=2
)

set -o pipefail
mkdir -p "${OUT_DIR}/dist"
cd "$KERNEL_SRC"

LOG="/tmp/build_${SOURCE_TYPE}.log"

echo "[${SOURCE_TYPE^^}] Building defconfig: $DEFCONFIG"
make "${MAKE_FLAGS[@]}" "$DEFCONFIG"

echo "[${SOURCE_TYPE^^}] Switching to ThinLTO..."
./scripts/config --file "${OUT_DIR}/dist/.config" \
  -e LTO_CLANG \
  -d LTO_NONE \
  -e LTO_CLANG_THIN \
  -d LTO_CLANG_FULL \
  -e THINLTO
make "${MAKE_FLAGS[@]}" olddefconfig

_FRAG_MERGED=false
if [ -n "${CLO_FRAGMENT:-}" ] && [ -f "arch/arm64/configs/${CLO_FRAGMENT}" ]; then
  echo "[${SOURCE_TYPE^^}] Merging platform fragment: $CLO_FRAGMENT"
  KCONFIG_CONFIG="${OUT_DIR}/dist/.config" \
    scripts/kconfig/merge_config.sh -m \
    "${OUT_DIR}/dist/.config" \
    "arch/arm64/configs/${CLO_FRAGMENT}"
  make "${MAKE_FLAGS[@]}" olddefconfig
  _FRAG_MERGED=true
fi

for _EXTRA in \
  "arch/arm64/configs/vendor/ext_config/moto-kalama.config" \
  "arch/arm64/configs/vendor/ext_config/moto-kalama-gki.config" \
  "arch/arm64/configs/vendor/ext_config/moto-kalama-rtwo.config"; do
  if [ -f "$_EXTRA" ]; then
    echo "[${SOURCE_TYPE^^}] Merging extra fragment: $_EXTRA"
    KCONFIG_CONFIG="${OUT_DIR}/dist/.config" \
      scripts/kconfig/merge_config.sh -m \
      "${OUT_DIR}/dist/.config" "$_EXTRA"
    make "${MAKE_FLAGS[@]}" olddefconfig
    _FRAG_MERGED=true
  else
    echo "[${SOURCE_TYPE^^}] Extra fragment not found, skipping: $_EXTRA"
  fi
done

if $_FRAG_MERGED; then
    echo "[MOTO] Re-enforcing ZRAM_DEF_COMP=lz4 after fragment merge"
    ./scripts/config --file "${OUT_DIR}/dist/.config" \
    -d ZRAM_DEF_COMP_LZORLE \
    -d ZRAM_DEF_COMP_ZSTD \
    -e ZRAM_DEF_COMP_LZ4 \
    -d ZRAM_DEF_COMP_LZO \
    --set-str ZRAM_DEF_COMP "lz4"
    echo "[MOTO] Re-enforcing TCP_CONG=westwood after fragment merge"
    ./scripts/config --file "${OUT_DIR}/dist/.config" \
    -e TCP_CONG_BBR \
    -e TCP_CONG_WESTWOOD \
    --set-str DEFAULT_TCP_CONG "westwood" \
    -d DEFAULT_BBR \
    -e DEFAULT_WESTWOOD
  make "${MAKE_FLAGS[@]}" olddefconfig
fi

echo "[${SOURCE_TYPE^^}] Building Image..."
if ! make "${MAKE_FLAGS[@]}" Image 2>&1 | tee "$LOG"; then
  echo "[FAIL] ${SOURCE_TYPE^^} build failed:"
  tail -100 "$LOG"
  exit 1
fi

if [ -f "${OUT_DIR}/dist/arch/arm64/boot/Image" ]; then
  cp "${OUT_DIR}/dist/arch/arm64/boot/Image" "${OUT_DIR}/dist/Image"
  echo "[${SOURCE_TYPE^^}] Image copied to ${OUT_DIR}/dist/Image"
else
  echo "[FAIL] Image file not found in build directory!"
  exit 1
fi

DURATION=$(( $(date +%s) - START ))
echo "✅ Build done in $((DURATION/60))m $((DURATION%60))s"
echo "duration=$DURATION" >> "${GITHUB_OUTPUT:-/dev/null}"
