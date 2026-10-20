#!/usr/bin/env bash
set -e

: "${ZIP_MODE:-per-variant}"
: "${BUILD_TYPE:-stable}"
: "${DATE_TAG:=$(date +'%Y%m%d')}"
: "${KERNEL_VERSION:-5.15.x}"

AK3_REPO="https://github.com/osm0sis/AnyKernel3"
mkdir -p ./release_zips

if [ "$ZIP_MODE" = "aio" ] || [ "$ZIP_MODE" = "both" ]; then
  [ "$BUILD_TYPE" = "testing" ] && SUFFIX="-testing" || SUFFIX=""
  _series=$(echo "${KERNEL_VERSION:-5.15.x}" | grep -oP '^\d+\.\d+' || echo "5.15")
  AIO_NAME="AK3-Blume-kernel-${_series}-$(date +'%Y-%m')${SUFFIX}.zip"

  git clone --depth=1 "$AK3_REPO" ak3_aio
  AK3_SOURCE_ZIP=$(find ./artifacts -type f -name "AK3-*.zip" | sort | head -1)
  [ -f "$AK3_SOURCE_ZIP" ] || { echo "[ERROR] No variant ZIP found"; exit 1; }
  unzip -p "$AK3_SOURCE_ZIP" anykernel.sh > ak3_aio/anykernel.sh
  chmod 755 ak3_aio/anykernel.sh
  grep -Fqx 'supported.versions=13-17' ak3_aio/anykernel.sh || { echo "[ERROR] AIO installer has incorrect Android support metadata"; exit 1; }
  grep -Fq 'BLUME-KERNEL | RTWO | SM8550' ak3_aio/anykernel.sh || { echo "[ERROR] AIO installer branding is missing"; exit 1; }
  grep -Eq '^[[:space:]]*split_boot[[:space:]]*$' ak3_aio/anykernel.sh || { echo "[ERROR] AIO installer does not read the boot image"; exit 1; }
  grep -Eq '^[[:space:]]*flash_boot[[:space:]]*$' ak3_aio/anykernel.sh || { echo "[ERROR] AIO installer does not flash the kernel image"; exit 1; }
  grep -Eq '^[[:space:]]*write_boot[[:space:]]*$' ak3_aio/anykernel.sh || { echo "[ERROR] AIO installer does not rebuild ramdisk boot images"; exit 1; }

  for ARTIFACT_DIR in ./artifacts/*/; do
    ARTIFACT_ZIP=$(find "$ARTIFACT_DIR" -name "AK3-*.zip" | head -1)
    [ -f "$ARTIFACT_ZIP" ] || continue

    DIR_NAME=$(basename "$ARTIFACT_DIR")
    case "$DIR_NAME" in
      blume-kernel-ksu-next) IMG_NAME="Image.blume.ksu" ;;
      blume-kernel-vanilla) IMG_NAME="Image.blume.vanilla" ;;
      *) IMG_NAME="Image.${DIR_NAME}" ;;
    esac

    mkdir -p /tmp/aio_extract
    unzip -o "$ARTIFACT_ZIP" Image -d /tmp/aio_extract/ 2>/dev/null || continue
    cp /tmp/aio_extract/Image "ak3_aio/${IMG_NAME}"
    rm -rf /tmp/aio_extract
  done

  ls -lh ak3_aio/Image.blume.* 2>/dev/null || { echo "[ERROR] No named images found"; exit 1; }
  cd ak3_aio
  zip -r9 "../release_zips/${AIO_NAME}" * -x .git/*
  cd ..
  rm -rf ak3_aio

  SIZE_MB=$(echo "scale=2; $(stat -c%s "./release_zips/${AIO_NAME}") / 1024 / 1024" | bc | sed 's/^\./0./')
  echo "[OK] AIO zip: $AIO_NAME ($SIZE_MB MB)"
fi

if [ "$ZIP_MODE" = "per-variant" ] || [ "$ZIP_MODE" = "both" ]; then
  find ./artifacts -name "AK3-*.zip" -exec cp {} ./release_zips/ \;
fi

ls -lh ./release_zips/
