#!/usr/bin/env bash
set -e

mkdir -p ./manager_apks

if [ -n "${KSUN_MANAGER_ARTIFACT_ID:-}" ]; then
  TMP_DIR="/tmp/mgr_ksu_next"
  mkdir -p "$TMP_DIR"
  curl -sfL --max-time 60 --location \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/KernelSU-Next/KernelSU-Next/actions/artifacts/${KSUN_MANAGER_ARTIFACT_ID}/zip" \
    -o "$TMP_DIR/artifact.zip" || true
  if [ -f "$TMP_DIR/artifact.zip" ]; then
    unzip -j "$TMP_DIR/artifact.zip" "*.apk" -d "$TMP_DIR" 2>/dev/null || true
    APK=$(find "$TMP_DIR" -name "*.apk" | head -1)
    [ -n "$APK" ] && cp "$APK" "./manager_apks/KSU-Next-manager-${KSUN_VERSION:-ci}.apk"
  fi
fi
