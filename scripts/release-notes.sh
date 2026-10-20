#!/usr/bin/env bash
set -e

: "${BUILD_TYPE:-stable}"
: "${RUN_URL:?}"
: "${REPO:?}"
: "${SHA:?}"

SHORT_SHA="${SHA:0:9}"
COMMIT_URL="https://github.com/${REPO}/commit/${SHA}"
BODY=""

if [ "$BUILD_TYPE" = "testing" ]; then
  BODY="${BODY}> [!WARNING]"$'\n'
  BODY="${BODY}> Testing build. Use it for validation and expect changes."$'\n\n'
fi

BODY="${BODY}**KSU-Next manager:** [CI build ↗](${KSUN_MANAGER_URL})"$'\n'
BODY="${BODY}**SUSFS module:** [${SUSFS_VERSION}](${SUSFS_MODULE_URL})"$'\n'
BODY="${BODY}**Kernel base:** \`${KERNEL_VERSION}\`"$'\n\n'
BODY="${BODY}**Variants:** Blume-kernel KSU-Next · Blume-kernel Vanilla"$'\n'
BODY="${BODY}**Device:** Motorola Edge 40 Pro (rtwo)"$'\n'
BODY="${BODY}**ROM:** AOSP or LineageOS-based"$'\n\n'
BODY="${BODY}> [!IMPORTANT]"$'\n'
BODY="${BODY}> The manager version must match the KSU-Next kernel version. Use the CI build linked above when root cannot be granted."$'\n\n'
BODY="${BODY}**Commit:** [\`${SHORT_SHA}\`](${COMMIT_URL})"$'\n'
BODY="${BODY}**Build details:** [Run #${GITHUB_RUN_NUMBER}](${RUN_URL})"$'\n'
BODY="${BODY}> Full logs are attached in the audit archive."

{
  echo "RELEASE_BODY<<EOREL"
  echo "$BODY"
  echo "EOREL"
} >> "${GITHUB_ENV:-/dev/null}"

echo "[OK] Release notes generated"
