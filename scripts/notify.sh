#!/usr/bin/env bash

MODE="${1:?usage: notify.sh <success|failure|check|variant-failure>}"

: "${TELEGRAM_BOT_TOKEN:?}"
: "${TELEGRAM_CHAT_ID:?}"

_tg_msg() {
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    ${TELEGRAM_TOPIC_ID:+-d message_thread_id="$TELEGRAM_TOPIC_ID"} \
    -d text="$1" \
    -d parse_mode="HTML" \
    -d disable_web_page_preview=true
}

_tg_doc() {
  local FILE="$1" CAPTION="$2"
  [ -f "$FILE" ] || return 0
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
    -F chat_id="$TELEGRAM_CHAT_ID" \
    ${TELEGRAM_TOPIC_ID:+-F message_thread_id="$TELEGRAM_TOPIC_ID"} \
    -F document=@"$FILE" \
    -F caption="$CAPTION"
}

if [ "$MODE" = "success" ]; then
  : "${RUN_URL:?}" "${RUN_NUMBER:?}" "${START_TIME:?}"
  : "${RELEASE_URL:-}" "${BUILD_TYPE:-stable}"

  SHORT_SHA="${SHA:0:9}"
  DURATION=$(( $(date +%s) - START_TIME ))
  DATE_STR=$(date -u +'%Y-%m-%d')
  DISPLAY_TAG=$(printf '%s' "${RELEASE_TAG}" | sed 's/+/%2B/g')
  DISPLAY_SUSFS=$(printf '%s' "${SUSFS_VERSION}" | sed 's/+/%2B/g')
  UNAME_STR="${KERNEL_UNAME:-${KERNEL_VERSION:-unknown}}"

  [ "$BUILD_TYPE" = "testing" ] && { ICON="🧪"; LABEL="Testing build"; } || { ICON="✅"; LABEL="Build success"; }

  MSG="<b>${ICON} ${LABEL}</b>%0A%0A"
  MSG="${MSG}<b>🔄</b> Blume-kernel · rtwo · run #${RUN_NUMBER}%0A"
  MSG="${MSG}<b>🏷️</b> <code>${DISPLAY_TAG}</code>%0A"
  MSG="${MSG}<b>🐧</b> <code>${UNAME_STR}</code>%0A"
  MSG="${MSG}<b>⏱️</b> $((DURATION/60))m $((DURATION%60))s%0A"
  MSG="${MSG}<b>🔨</b> <a href='https://github.com/${GITHUB_REPOSITORY}/commit/${SHA}'>${SHORT_SHA}</a>%0A%0A"
  MSG="${MSG}<b>📦 Variants</b>%0A"
  MSG="${MSG}• KSU-Next + SUSFS%0A"
  MSG="${MSG}• Vanilla%0A"
  MSG="${MSG}<b>📦 SUSFS</b> <code>${DISPLAY_SUSFS}</code>%0A%0A"
  MSG="${MSG}<b>📋</b> ${DATE_STR} · ${BUILD_TYPE}%0A"
  MSG="${MSG}<b>🔗</b> <a href='${RELEASE_URL}'>Release</a> · <a href='${RUN_URL}'>Logs</a>"
  _tg_msg "$MSG"

  for ZIP in ./release_zips/*.zip; do
    [ -f "$ZIP" ] || continue
    SIZE_MB=$(echo "scale=2; $(stat -c%s "$ZIP") / 1024 / 1024" | bc | sed 's/^\./0./')
    _tg_doc "$ZIP" "📦 $(basename "$ZIP") — ${SIZE_MB} MB"
  done

  if [ -n "${LOG_AUDIT_ZIP:-}" ] && [ -f "$LOG_AUDIT_ZIP" ]; then
    if (( $(echo "${LOG_AUDIT_SIZE_MB:-0} < 45" | bc -l) )); then
      _tg_doc "$LOG_AUDIT_ZIP" "📋 $(basename "$LOG_AUDIT_ZIP") — ${LOG_AUDIT_SIZE_MB} MB"
    else
      _tg_msg "📋 Log too large (${LOG_AUDIT_SIZE_MB} MB) — grab it from <a href='${RELEASE_URL}'>the release</a>."
    fi
  fi
elif [ "$MODE" = "failure" ]; then
  : "${RUN_URL:?}" "${RUN_NUMBER:?}"
  STATUS="${BUILD_STATUS:-failed}"
  [ "$STATUS" = "cancelled" ] && { ICON="⚠️"; LABEL="Cancelled"; } || { ICON="❌"; LABEL="Build failed"; }
  MSG="<b>${ICON} ${LABEL}</b>%0A%0A"
  MSG="${MSG}<b>🔄</b> Blume-kernel · run #${RUN_NUMBER}%0A"
  MSG="${MSG}<b>🕐</b> $(date -u +'%Y-%m-%d %H:%M UTC')%0A"
  MSG="${MSG}<b>🔗</b> <a href='${RUN_URL}'>Logs</a>"
  _tg_msg "$MSG"
elif [ "$MODE" = "check" ]; then
  : "${RUN_URL:?}"
  DISPLAY_SUSFS_TAG=$(printf '%s' "${CHECK_SUSFS_TAG:-?}" | sed 's/+/%2B/g')
  [ "${HAS_UPDATE:-false}" = "true" ] && STATUS_LINE="<b>🆕 Updates available</b>" || STATUS_LINE="<b>✅ All sources up to date</b>"
  MSG="<b>🔍 Source update check</b>%0A%0A"
  MSG="${MSG}${STATUS_LINE}%0A%0A"
  MSG="${MSG}<b>Moto 5.15:</b> <code>${CHECK_MOTO_SUB:-?}</code>%0A"
  MSG="${MSG}<b>KSU-Next:</b> <code>${CHECK_KSUN_TAG:-?}</code>%0A"
  MSG="${MSG}<b>WildKernels:</b> <code>${CHECK_WILDKERNELS_COMMIT:0:9}</code>%0A"
  MSG="${MSG}<b>SUSFS:</b> <code>${DISPLAY_SUSFS_TAG}</code>%0A"
  if [ "${HAS_UPDATE:-false}" = "true" ] && [ -n "${UPDATE_DETAIL:-}" ]; then
    MSG="${MSG}%0A<b>Changes:</b>%0A"
    while IFS= read -r LINE; do
      [ -z "$LINE" ] || MSG="${MSG}▸ $(printf '%s' "$LINE" | sed 's/+/%2B/g')%0A"
    done <<< "$UPDATE_DETAIL"
  fi
  MSG="${MSG}%0A%0A<b>🔗</b> <a href='${RUN_URL}'>Run details</a>"
  _tg_msg "$MSG"
elif [ "$MODE" = "variant-failure" ]; then
  : "${RUN_URL:?}" "${RUN_NUMBER:?}" "${VARIANT:?}"
  LOG_FILE="/tmp/build_${SOURCE_TYPE:-gki}.log"
  ERRORS=""
  if [ -f "$LOG_FILE" ]; then
    ERRORS=$(grep -E " error:" "$LOG_FILE" | sed 's|.*/kernel_src/||' | awk '!seen[$0]++' | tail -20 | head -c 1800)
  fi
  [ "$BUILD_TYPE" = "testing" ] && TYPE_ICON="🧪" || TYPE_ICON="🔨"
  MSG="<b>❌ Build failed — ${VARIANT}</b>%0A%0A"
  MSG="${MSG}<b>${TYPE_ICON}</b> ${BUILD_TYPE:-stable} · run #${RUN_NUMBER}%0A"
  MSG="${MSG}<b>🕐</b> $(date -u +'%H:%M UTC')%0A"
  MSG="${MSG}<b>🔗</b> <a href='${RUN_URL}'>Logs</a>"
  [ -z "$ERRORS" ] || MSG="${MSG}%0A%0A<b>Errors:</b>%0A<pre>${ERRORS}</pre>"
  _tg_msg "$MSG"
else
  echo "[ERROR] Unknown mode: $MODE"
  exit 1
fi
