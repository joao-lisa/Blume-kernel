#!/usr/bin/env bash
set -e

: "${SOURCE_TYPE:?}"
: "${KERNEL_SRC:=$WORK_DIR/kernel_src}"

mkdir -p "$KERNEL_SRC"

case "$SOURCE_TYPE" in

  moto)
    MOTO_REPO="https://github.com/LineageOS/android_kernel_motorola_sm8550"
    MOTO_BRANCH="lineage-23.2"
    if [ "${MOTO_CACHE_HIT}" = "true" ] && [ -d "$KERNEL_SRC/.git" ]; then
      echo "[Moto] Cache hit — fetching delta only..."
      for attempt in 1 2 3; do
        git -C "$KERNEL_SRC" fetch origin --depth=1 "$MOTO_BRANCH" && \
          git -C "$KERNEL_SRC" reset --hard FETCH_HEAD && break
        echo "⚠️ Fetch attempt $attempt failed, retrying in 30s..."
        sleep 30
      done
    else
      echo "[Moto] Cloning $MOTO_BRANCH ..."
      for attempt in 1 2 3; do
        git clone --recursive --branch "$MOTO_BRANCH" "$MOTO_REPO" "$KERNEL_SRC" --depth=1 && break
        echo "⚠️ Attempt $attempt failed, retrying in 30s..."
        rm -rf "$KERNEL_SRC" && mkdir -p "$KERNEL_SRC"
        sleep 30
      done
    fi
    ;;

  *)
    echo "[ERROR] Unknown source type: $SOURCE_TYPE"
    exit 1
    ;;
esac

echo "[OK] Source cloned → $KERNEL_SRC"
echo "KERNEL_SRC=$KERNEL_SRC" >> "${GITHUB_ENV:-/dev/null}"
