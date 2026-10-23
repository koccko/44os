# 44OS

44OS is a Debian 13 "trixie" based live/installable Linux distribution with a
minimal, dark KDE Plasma 6 desktop and the Calamares installer.

## Desktop

- **Top bar**: 44OS launcher, global menu, centered clock, system tray.
- **Dock**: floating, centered, sized to its content (Files, Firefox,
  Konsole, Kate, System Settings).
- **Look**: the 44OS dark palette, Inter UI font, Breeze/Breeze Dark icons,
  centered window titles, macOS-style window buttons on the left.
- **Same branding everywhere**: desktop, lock screen, SDDM login screen and the
  Calamares installer share the 44OS mark and "Horizon" wallpaper.

The layout ships as a Plasma look-and-feel package (`org.44os.desktop`). Plasma
applies it only when a user has no desktop configuration yet, so it never
touches an existing user's layout.

## Repository layout

| Path | Purpose |
| --- | --- |
| `build-44os.sh` | live-build driver (run as root on Debian trixie) |
| `config/package-lists/` | packages in the live image |
| `config/includes.chroot/` | files copied into the image (branding, defaults) |
| `config/hooks/live/` | chroot hooks (Calamares branding, launcher clean-up, checks) |
| `branding/` | SVG sources plus `render.sh`/`colors.py` that regenerate the committed assets |
| `scripts/verify-iso.sh` | static check of the ISO boot structures (BIOS + UEFI) |
| `.github/scripts/boot-test.sh` | automated QEMU/VirtualBox boot test |

## Build

GitHub Actions → **Build 44OS Live ISO** → *Run workflow*. The workflow:

1. builds the ISO in a `debian:trixie` container,
2. runs `scripts/verify-iso.sh` (El Torito BIOS/UEFI entries, `EFI/BOOT/BOOTX64.EFI`
   inside the EFI image, kernel/initrd/squashfs, GRUB live entry),
3. boots the ISO headless: QEMU+OVMF UEFI (DVD and USB), UEFI Secure Boot,
   BIOS, a full UEFI boot up to `graphical.target`, and VirtualBox EFI.

The ISO is uploaded as the `44OS-<version>-live-amd64` artifact (a zip that
contains the `.iso` and `SHA256SUMS`). Unzip it before attaching the `.iso` to a VM.

Local build (Debian trixie, root): `sudo ./build-44os.sh` → `dist/`.

## VirtualBox

Create a *Linux / Debian (64-bit)* VM, 4 GB RAM or more, and tick
*Enable EFI* if you want UEFI. Attach the extracted `.iso` to the optical drive,
not the `.zip`. Select **Live system** in the boot menu; use **Install 44OS** on the
desktop to install.

## Regenerating branding

```sh
sudo apt install librsvg2-bin imagemagick fonts-inter python3
branding/render.sh
```
