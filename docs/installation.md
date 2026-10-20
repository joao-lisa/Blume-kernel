# Installation

> ⚠️ **Flash via OrangeFox / TWRP only.**

1. Download a ZIP from [Releases](../../releases)
2. Boot into recovery
3. Flash the ZIP
4. Reboot

> Using **Magisk**? Re-patch your boot image after flashing.

---

## Manager

The KSU-Next build embeds a specific manager version code.
Your manager APK must match that code — a mismatch means apps can't be granted root.

**Use the CI Build links in the release notes, not the stable release.**

- If it shows `Failed to update App Profile`, use the manager linked in the release notes.
- Correct manager build is always linked directly in the release body.

### Finding the manager in CI artifacts

Click the CI Build link, download the artifact ZIP, extract the manager APK and install it.

If you see "absolute gibberish" on the artifacts page: you're looking at the raw artifact list. Just grab any ZIP and extract it — the `manager` APK is inside.

---

## Troubleshooting

### Boot Modes

Recovery: Turn off the device → hold Volume Down + Power → select "Recovery mode" with the Volume buttons.

Fastboot/Bootloader: Turn off the device → hold Volume Down + Power (hold until the bootloader enters).

For help, open an issue with the build log and device details.
