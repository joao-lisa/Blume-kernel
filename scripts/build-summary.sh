#!/usr/bin/env bash
set -e

: "${VARIANT:?}"
: "${KSU_TYPE:?}"
: "${SOURCE_TYPE:?}"
: "${BUILD_TYPE:-stable}"
: "${RUN_URL:-}"

case "$KSU_TYPE" in
  ksun)
    KSU_LABEL="KSU-Next"
    BBG="enabled"
    SUSFS_NOTE="enabled"
    ;;
  none)
    KSU_LABEL="Vanilla"
    BBG="disabled"
    SUSFS_NOTE="disabled"
    ;;
  *)
    KSU_LABEL="$KSU_TYPE"
    BBG="unknown"
    SUSFS_NOTE="unknown"
    ;;
esac

[ "$BUILD_TYPE" = "testing" ] && BUILD_BADGE="testing" || BUILD_BADGE="stable"

echo "Build summary"
echo "Variant : $VARIANT"
echo "Type    : $BUILD_BADGE"
echo "Kernel  : ${KERNEL_VERSION:-unknown}"
echo "Source  : $SOURCE_TYPE"
echo "Root    : $KSU_LABEL"
echo "SUSFS   : $SUSFS_NOTE"
echo "BBG     : $BBG"
echo "Run     : $RUN_URL"
