#!/usr/bin/env bash
set -e

: "${BUILD_TYPE:-stable}"
: "${REPO:?}"
: "${SHA:?}"

SHORT_SHA="${SHA:0:9}"
COMMIT_URL="https://github.com/${REPO}/commit/${SHA}"
DATE_NOW=$(date -u +'%Y-%m-%d %H:%M UTC')
[ "$BUILD_TYPE" = "testing" ] && BUILD_LABEL="testing" || BUILD_LABEL="stable"

VARIANT_TABLE=""
for ZIP in ./release_zips/AK3-*.zip; do
  [ -f "$ZIP" ] || continue
  NAME=$(basename "$ZIP")
  SIZE=$(echo "scale=1; $(stat -c%s "$ZIP") / 1024 / 1024" | bc)
  VARIANT_TABLE="${VARIANT_TABLE}"$'\n'"| [\`${NAME}\`](${RELEASE_URL}) | ${SIZE} MB |"
done

SUMMARY=""
SUMMARY="${SUMMARY}# Blume-kernel rtwo — build summary"$'\n\n'
SUMMARY="${SUMMARY}| | |"$'\n'
SUMMARY="${SUMMARY}|---|---|"$'\n'
SUMMARY="${SUMMARY}| **Build** | Run #${GITHUB_RUN_NUMBER} · ${BUILD_LABEL} |"$'\n'
SUMMARY="${SUMMARY}| **Tag** | \`${RELEASE_TAG}\` |"$'\n'
SUMMARY="${SUMMARY}| **Kernel base** | \`${KERNEL_VERSION}\` |"$'\n'
SUMMARY="${SUMMARY}| **Commit** | [\`${SHORT_SHA}\`](${COMMIT_URL}) |"$'\n'
SUMMARY="${SUMMARY}| **Date** | ${DATE_NOW} |"$'\n'
SUMMARY="${SUMMARY}| **Pack mode** | ${ZIP_MODE:-per-variant} |"$'\n\n'

SUMMARY="${SUMMARY}## KSU-Next and SUSFS"$'\n\n'
SUMMARY="${SUMMARY}| Component | Version | Link |"$'\n'
SUMMARY="${SUMMARY}|-----------|---------|------|"$'\n'
SUMMARY="${SUMMARY}| KSU-Next | \`${KSUN_TAG}\` | [Releases](https://github.com/KernelSU-Next/KernelSU-Next/releases/tag/${KSUN_TAG}) |"$'\n'
SUMMARY="${SUMMARY}| SUSFS module | \`${SUSFS_VERSION}\` | [Download](${SUSFS_MODULE_URL}) |"$'\n\n'

SUMMARY="${SUMMARY}## Features"$'\n\n'
SUMMARY="${SUMMARY}- SUSFS"$'\n'
SUMMARY="${SUMMARY}- BBR and Westwood TCP"$'\n'
SUMMARY="${SUMMARY}- BBG on the KSU-Next variant"$'\n'
SUMMARY="${SUMMARY}- Thin LTO"$'\n'
SUMMARY="${SUMMARY}- Droidspaces"$'\n\n'

SUMMARY="${SUMMARY}## Variants and downloads"$'\n\n'
SUMMARY="${SUMMARY}| File | Size |"$'\n'
SUMMARY="${SUMMARY}|------|------|"
SUMMARY="${SUMMARY}${VARIANT_TABLE}"$'\n\n'
SUMMARY="${SUMMARY}[Release page](${RELEASE_URL})"$'\n\n'
SUMMARY="${SUMMARY}---"$'\n'
SUMMARY="${SUMMARY}> Runner summary retention is limited. Full details are in the audit log archive."

echo "$SUMMARY" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
mkdir -p ./audit_logs
echo "$SUMMARY" > ./audit_logs/build_summary.md
echo "[OK] Release summary written"
