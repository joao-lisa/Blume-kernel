#!/usr/bin/env bash

properties() { '
kernel.string=Blume-kernel — rtwo
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=rtwo
supported.versions=13-16
supported.patchlevels=
supported.vendorpatchlevels=
'; }

boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin
}

BLOCK=boot
IS_SLOT_DEVICE=auto
RAMDISK_COMPRESSION=auto
PATCH_VBMETA_FLAG=auto

. tools/ak3-core.sh

HAS_KSU=0
HAS_VANILLA=0
HAS_SINGLE=0
[ -f "$AKHOME/Image.blume.ksu" ] && HAS_KSU=1
[ -f "$AKHOME/Image.blume.vanilla" ] && HAS_VANILLA=1
[ -f "$AKHOME/Image" ] && HAS_SINGLE=1
TOTAL=$((HAS_KSU + HAS_VANILLA))
SELECTED_IMAGE=""

flush_keys() { sleep 0.15; }

if [ "$TOTAL" -gt 1 ]; then
  ui_print " "
  ui_print "  Select variant  (vol+ = next  |  vol- = confirm)"
  OPTION=1

  print_menu() {
    ui_print " "
    I=0
    [ "$HAS_VANILLA" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && ui_print "  > Vanilla" || ui_print "    Vanilla"; }
    [ "$HAS_KSU" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && ui_print "  > KSU-Next + SUSFS" || ui_print "    KSU-Next + SUSFS"; }
  }

  print_menu
  flush_keys
  while true; do
    input=$(getevent -qlc 1 2>/dev/null)
    case "$input" in
      *KEY_VOLUMEUP*DOWN*)
        OPTION=$((OPTION % TOTAL + 1))
        print_menu
        flush_keys
        ;;
      *KEY_VOLUMEDOWN*DOWN*)
        flush_keys
        break
        ;;
    esac
  done

  I=0
  [ "$HAS_VANILLA" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && { SELECTED_IMAGE="Image.blume.vanilla"; ui_print "  >> Vanilla"; }; }
  [ "$HAS_KSU" = "1" ] && { I=$((I+1)); [ "$OPTION" = "$I" ] && { SELECTED_IMAGE="Image.blume.ksu"; ui_print "  >> KSU-Next + SUSFS"; }; }
elif [ "$HAS_VANILLA" = "1" ]; then
  SELECTED_IMAGE="Image.blume.vanilla"
  ui_print "  >> Vanilla"
elif [ "$HAS_KSU" = "1" ]; then
  SELECTED_IMAGE="Image.blume.ksu"
  ui_print "  >> KSU-Next + SUSFS"
elif [ "$HAS_SINGLE" = "1" ]; then
  SELECTED_IMAGE="Image"
  ui_print "  >> Current variant"
fi

[ -n "$SELECTED_IMAGE" ] || abort "No kernel image found"
[ "$SELECTED_IMAGE" = "Image" ] || mv "$AKHOME/$SELECTED_IMAGE" "$AKHOME/Image"
