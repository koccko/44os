#!/usr/bin/env bash
# Static validation of a 44OS ISO's boot structures. Fails if the image could
# not boot on UEFI or BIOS machines (missing El Torito entries, EFI image
# without a removable-media loader, missing kernel/initrd/squashfs, ...).
# Requires: xorriso, mtools.
set -Eeuo pipefail
ISO="${1:?usage: verify-iso.sh <iso>}"
fail() { echo "VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "  ok: $*"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

echo "=== Verifying $ISO"
size=$(stat -c %s "$ISO"); echo "  size: $size bytes"

xorriso -indev "$ISO" -report_el_torito plain -report_system_area plain >"$tmp/report" 2>&1 \
  || fail "xorriso could not read the image"
sed -n '/El Torito/p;/System area/p;/Partition/p;/GPT/p;/MBR/p' "$tmp/report" | sed 's/^/    /' | head -n 40

grep -Eq 'El Torito boot img :[[:space:]]+[0-9]+[[:space:]]+BIOS' "$tmp/report" || fail "no BIOS El Torito boot image"
ok "BIOS El Torito entry"
grep -Eq 'El Torito boot img :[[:space:]]+[0-9]+[[:space:]]+UEFI' "$tmp/report" || fail "no UEFI El Torito boot image"
ok "UEFI El Torito entry"

# Locate the EFI boot image (a FAT filesystem) and inspect it. Report lines:
#   El Torito boot img :   2  UEFI  y   none  0x0000  0x00   6656         135
#   El Torito img path :   2  /boot/grub/efi.img
uefi_idx=$(awk '/^El Torito boot img :/ && $7=="UEFI" {print $6; exit}' "$tmp/report")
uefi_lba=$(awk '/^El Torito boot img :/ && $7=="UEFI" {print $NF; exit}' "$tmp/report")
uefi_blks=$(awk '/^El Torito boot img :/ && $7=="UEFI" {print $(NF-1); exit}' "$tmp/report")
efi_path=$(awk -v i="$uefi_idx" '/^El Torito img path :/ && $6==i {print $7; exit}' "$tmp/report")
if [[ -n "$efi_path" ]]; then
  osirrox -indev "$ISO" -extract "$efi_path" "$tmp/efi.img" >/dev/null 2>&1 || fail "cannot extract $efi_path"
else
  # Hidden or appended image: read it by LBA (2048-byte) and size (512-byte blocks).
  [[ -n "$uefi_lba" && "$uefi_blks" -gt 0 ]] || fail "cannot locate the UEFI boot image"
  dd if="$ISO" of="$tmp/efi.img" bs=512 skip=$((uefi_lba * 4)) count="$uefi_blks" status=none
  efi_path="LBA $uefi_lba"
fi
ok "EFI boot image $efi_path ($(stat -c %s "$tmp/efi.img") bytes)"
mdir -/ -b -i "$tmp/efi.img" :: >"$tmp/efi.list" 2>&1 || fail "EFI boot image is not a readable FAT filesystem"
sed 's/^/    /' "$tmp/efi.list"
grep -qi '^::/EFI/BOOT/BOOTX64.EFI$' "$tmp/efi.list" || fail "EFI image lacks \\EFI\\BOOT\\BOOTX64.EFI (firmware has nothing to start)"
ok "removable-media loader \\EFI\\BOOT\\BOOTX64.EFI"
if grep -qi '^::/EFI/BOOT/GRUBX64.EFI$' "$tmp/efi.list"; then ok "signed GRUB next to shim (Secure Boot chain)"; fi

# Hybrid USB boot: an ESP entry must exist in the partition tables.
if grep -Eq 'GPT.*(EFI System|28732ac11ff8d211ba4b00a0c93ec93b)|MBR partition.*0xef|0xef' "$tmp/report"; then
  ok "EFI System Partition entry for USB boot"
else
  echo "  warn: no ESP entry in MBR/GPT; USB-stick UEFI boot may fail" >&2
fi

# Payload checks.
xorriso -indev "$ISO" -find /live -type f -exec lsdl >"$tmp/live" 2>/dev/null || true
grep -q '/live/vmlinuz' "$tmp/live" || fail "no kernel in /live"
grep -q '/live/initrd' "$tmp/live" || fail "no initrd in /live"
grep -q '/live/filesystem.squashfs' "$tmp/live" || fail "no /live/filesystem.squashfs"
ok "kernel, initrd and squashfs present"

osirrox -indev "$ISO" -extract /boot/grub/grub.cfg "$tmp/grub.cfg" >/dev/null 2>&1 || fail "no /boot/grub/grub.cfg"
grep -q 'boot=live' "$tmp/grub.cfg" || \
  { osirrox -indev "$ISO" -extract /boot/grub "$tmp/grub" >/dev/null 2>&1; grep -rqs 'boot=live' "$tmp/grub"; } || \
  fail "GRUB configuration has no live boot entry"
ok "GRUB live boot entry"
echo "=== ISO boot structure verified"
