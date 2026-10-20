# Variants & Features

## Variants

| Variant | Source | Root | Extras |
|---------|--------|------|--------|
| Blume-KSU-Next | LineageOS SM8550 | KernelSU-Next + SUSFS | BBG |
| Blume-Vanilla | LineageOS SM8550 | Vanilla | — |

All variants include: **WildKernels optimization patches** · **LZ4 ZRAM** · **Thin LTO** · **Droidspaces support**

---

## Droidspaces Support

This kernel ships with [Droidspaces](https://github.com/ravindu644/Droidspaces-OSS) container support.

Enabled configs: `SYSVIPC` · `IPC_NS` · `PID_NS` · `POSIX_MQUEUE` · `DEVTMPFS` · Netfilter extras

kABI fix applied for GKI < 6.12 to prevent vendor module crashes on boot.

> **SuSFS users:** disable **"HIDE SUS MOUNTS FOR ALL PROCESSES"** in SuSFS4KSU settings, otherwise containers will fail to start.

---

## Build Details

| | Blume-kernel |
|--|---------------------|
| Source | `LineageOS/android_kernel_motorola_sm8550` |
| Branch | `lineage-23.2` |
| Config base | `gki_defconfig` |
| Platform fragment | `vendor/kalama_GKI.config` (if present) |
| Device fragments | `moto-kalama.config` · `moto-kalama-gki.config` · `moto-kalama-rtwo.config` |
| Toolchain | Clang r563880c |
| LTO | Thin |
