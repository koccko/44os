# 44OS verification status

This file records what has been verified, how, and what is still unverified.
Update it with every release; never mark something verified without evidence.

## Baseline: 44OS 0.5 Alpha (`fix/uefi-boot-desktop-refresh` @ 3aa6b49)

### Confirmed working

| Area | Evidence |
| --- | --- |
| ISO build (live-build, Debian 13) | GitHub Actions run 39980312636: build + `scripts/verify-iso.sh` pass |
| ISO boot structures | `verify-iso.sh`: BIOS + UEFI El Torito, `EFI/BOOT/BOOTX64.EFI` (shim) + `grubx64.efi`, kernel, initrd, squashfs |
| UEFI boot, DVD | QEMU + OVMF, unmodified ISO reaches the GRUB menu (OCR) |
| UEFI boot, USB stick | QEMU + OVMF, ISO attached as USB mass storage reaches the GRUB menu |
| UEFI Secure Boot | QEMU + OVMF with Microsoft keys: shim → GRUB → kernel → `44os login:` |
| BIOS boot | QEMU + SeaBIOS reaches the isolinux menu |
| VirtualBox EFI | VirtualBox 7.0 (Ubuntu 24.04 runner), EFI firmware, reaches the GRUB menu |
| Live desktop | QEMU UEFI full boot: `sddm.service` started, autologin into Plasma; screenshots show top bar (44 launcher, centered clock, tray), floating centered dock (Files, Firefox, Konsole, Kate, System Settings), Horizon wallpaper, single "Install 44OS" icon, no KDE Welcome popup |
| Real VirtualBox use | Reported by the project owner: Plasma 6.3.6, Frameworks 6.13, Qt 6.8.2 on llvmpipe |
| Old 0.3/0.4 ISOs | Both reach GRUB in QEMU (UEFI/SB/BIOS) and VirtualBox EFI; identical boot structures |

### Not yet verified

| Area | Notes |
| --- | --- |
| Calamares end-to-end install | Never run in CI. A login-password problem was reported for an earlier development build after installation. |
| Boot from disk without the ISO | Depends on the install test |
| Password authentication after install (TTY, SDDM), password change | Depends on the install test |
| Real UEFI hardware | Not available in CI |
| Live boot menu branding | Still live-build's stock Debian artwork |
