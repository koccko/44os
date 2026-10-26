# Testing 44OS

## Automated (GitHub Actions: *Build 44OS Live ISO*)

| Stage | What runs | Blocking |
| --- | --- | --- |
| Lint | `bash -n`/`sh -n` for scripts and hooks, Python/JSON checks, QML parse check (`scripts/check-qml.py`), every package in `config/package-lists` exists in trixie (`scripts/check-packages.sh`) | yes |
| Build | live-build; chroot hooks fail the build if branding files or 44Welcome's PyQt6/QML dependencies are missing | yes |
| Static ISO check | `scripts/verify-iso.sh`: BIOS + UEFI El Torito entries, `\EFI\BOOT\BOOTX64.EFI` in the EFI image, kernel/initrd/squashfs, GRUB live entry | yes |
| boot-test | QEMU + OVMF: UEFI DVD and USB reach GRUB; Secure Boot (Microsoft keys) boots into the kernel; SeaBIOS reaches isolinux | yes |
| desktop-test | Live session (UEFI): 44Welcome autostart + persisted completion, panel/plasmoid config, no QML errors from 44OS plasmoids, 44NOVA decoration, top bar, dock hover, launching an app from the dock, KRunner (D-Bus and Super+Space), Dolphin window + global menu, About this System, 44Welcome pages. Screenshots of each. | yes (some checks are warnings) |
| install-test | Calamares driven by OCR + mouse/keyboard: erase disk, user with a random password; reboot **without the ISO**; SDDM login; 44Welcome on first login; TTY login, `id`, root device, no live medium; `passwd` change, old password rejected, new one works; second reboot + SDDM login with the new password, no second welcome; empty-NVRAM boot via the fallback loader; a second disk attached during installation is bit-identical afterwards | yes (some checks are warnings) |
| VirtualBox | VirtualBox 7 (runner) EFI reaches the GRUB menu | no (runner support varies) |

Each runtime job writes `summary.txt` (`PASS`/`FAIL`/`WARN` per check) and
screenshots, uploaded as artifacts and, for runs in this repository, pushed to
`ci-results/<run-id>-<job>` branches.

Re-run only the tests against an existing ISO: *Run workflow* with
`iso_run_id` = the run that built it.

## Manual checklist (real hardware / your VirtualBox)

1. Boot the ISO in UEFI mode → 44OS NOVA boot splash → live desktop.
2. 44Welcome opens once; close it; it can be reopened from the menu.
3. Top bar: click the network, volume, battery/brightness, Bluetooth and
   notification icons; each opens its native popup.
4. Dock: hover (magnification), click Files (opens, indicator appears),
   right-click → *Keep in Dock* / *Remove from Dock*.
5. Super+Space → type `12*12` → 144; type an app name → Enter launches it.
6. Install with *Install 44OS* → reboot → **remove the ISO** → log in on SDDM
   → open a terminal → `passwd` → log out and back in with the new password.
7. Dual boot with Windows: **not yet tested by the project**; back up first and
   use *Manual partitioning* if unsure.
