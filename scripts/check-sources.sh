#!/usr/bin/env bash
set -e

PINS_FILE="sources/source-pins.json"

_curl() { curl -s --retry 3 --retry-delay 2 "$@" || echo ""; }
_pin() { jq -r ".${1} // \"unknown\"" "$PINS_FILE" 2>/dev/null || echo "unknown"; }

KSUN_TAG=$(_curl "https://api.github.com/repos/KernelSU-Next/KernelSU-Next/tags" | jq -r '.[0].name // "unknown"' 2>/dev/null || echo "unknown")
[ -n "$KSUN_TAG" ] || KSUN_TAG="unknown"

SUSFS_TAG=$(_curl "https://api.github.com/repos/sidex15/susfs4ksu-module/tags" | jq -r 'if type=="array" and length>0 then .[0].name else "unknown" end' 2>/dev/null || echo "unknown")
[ -n "$SUSFS_TAG" ] || SUSFS_TAG="unknown"

MOTO_RAW=$(_curl "https://raw.githubusercontent.com/LineageOS/android_kernel_motorola_sm8550/lineage-23.2/Makefile")
MOTO_SUB=$(echo "$MOTO_RAW" | awk -F' *= *' '/^VERSION / {v=$2} /^PATCHLEVEL / {p=$2} /^SUBLEVEL / {s=$2} END {if (v && p && s) print "v"v"."p"."s; else print "unknown"}')
MOTO_SUB="${MOTO_SUB:-unknown}"

PIN_MOTO=$(_pin "moto_sublevel")
PIN_KSUN=$(_pin "ksun_tag")
PIN_SUSFS=$(_pin "susfs_tag")
UPDATES=()
[ "$MOTO_SUB" != "$PIN_MOTO" ] && UPDATES+=("moto: ${PIN_MOTO} -> ${MOTO_SUB}")
[ "$KSUN_TAG" != "$PIN_KSUN" ] && UPDATES+=("ksu-next: ${PIN_KSUN} -> ${KSUN_TAG}")
[ "$SUSFS_TAG" != "$PIN_SUSFS" ] && UPDATES+=("susfs: ${PIN_SUSFS} -> ${SUSFS_TAG}")

if [ "${#UPDATES[@]}" -gt 0 ]; then
  HAS_UPDATE="true"
  UPDATE_DETAIL=$(printf '%s\n' "${UPDATES[@]}")
else
  HAS_UPDATE="false"
  UPDATE_DETAIL=""
fi

{
  echo "CHECK_KSUN_TAG=$KSUN_TAG"
  echo "CHECK_SUSFS_TAG=$SUSFS_TAG"
  echo "CHECK_MOTO_SUB=$MOTO_SUB"
  echo "HAS_UPDATE=$HAS_UPDATE"
  echo "UPDATE_DETAIL<<EOF"
  echo "$UPDATE_DETAIL"
  echo "EOF"
} >> "${GITHUB_ENV:-/dev/null}"

echo "[OK] Source check complete"
