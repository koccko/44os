#!/usr/bin/env bash
# Build the 44OS live ISO (Debian 13 "trixie" + KDE Plasma 6 + Calamares).
# Must run as root on a Debian trixie host/container with live-build.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$ROOT/work"
DIST="$ROOT/dist"
VERSION="${VERSION:-0.5-alpha}"
ISO_NAME="44OS-${VERSION}-live-amd64.iso"

if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: Run as root"
  exit 1
fi

echo "=================================="
echo "       44OS ${VERSION} BUILD"
echo "=================================="

rm -rf "$WORK"
mkdir -p "$WORK" "$DIST"
cd "$WORK"

# Bootloaders are set explicitly instead of relying on live-build defaults:
#   grub-efi -> UEFI boot (El Torito EFI image + GPT/ESP for USB sticks)
#   syslinux -> legacy BIOS boot (isolinux)
lb config \
  --mode debian \
  --distribution trixie \
  --architecture amd64 \
  --binary-images iso-hybrid \
  --bootloaders "grub-efi,syslinux" \
  --uefi-secure-boot enable \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap "https://deb.debian.org/debian/" \
  --mirror-chroot "https://deb.debian.org/debian/" \
  --mirror-binary "https://deb.debian.org/debian/" \
  --security true \
  --mirror-chroot-security "https://security.debian.org/debian-security/" \
  --mirror-binary-security "https://security.debian.org/debian-security/" \
  --iso-application "44OS" \
  --iso-publisher "44OS" \
  --iso-volume "44OS" \
  --bootappend-live "boot=live components quiet splash hostname=44os" \
  --debian-installer none \
  --apt-recommends true

# Copy our custom package lists and configuration
cp -a "$ROOT/config/." "$WORK/config/"
chmod 755 "$WORK"/config/hooks/live/*.hook.chroot

echo "=== 44OS BUILD CONFIG ==="
grep -E 'LB_(DISTRIBUTION|BOOTLOADERS|UEFI_SECURE_BOOT|BINARY_IMAGES|SECURITY)=' \
  config/* 2>/dev/null || true

echo "=== BUILDING 44OS ==="
lb build

ISO="$(find "$WORK" -maxdepth 1 -type f -name '*.iso' -print -quit)"

if [[ -z "$ISO" ]]; then
  echo "ERROR: ISO file was not generated"
  exit 1
fi

cp "$ISO" "$DIST/$ISO_NAME"
"$ROOT/scripts/verify-iso.sh" "$DIST/$ISO_NAME"

echo "=================================="
echo "  44OS ISO BUILD COMPLETED"
echo "=================================="
ls -lh "$DIST"
