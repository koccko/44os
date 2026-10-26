# 44OS 0.6 Alpha — NOVA Edition

44OS is a Debian 13 "trixie" based Linux distribution with a calm,
macOS-inspired KDE Plasma 6 desktop and its own futuristic identity, the
**NOVA Glass** design system. It installs with Calamares and boots on UEFI
(including Secure Boot) and legacy BIOS machines.

> **Status:** alpha. What has been verified, and how, is recorded in
> [docs/STATUS.md](docs/STATUS.md). Build success alone is never treated as
> proof that something works.

## The desktop

| Component | What it is |
| --- | --- |
| **Menu bar** | Top panel: 44 launcher, active application name, global application menu (KDE apps), quick-settings tray, clock |
| **44Dock** | Floating, centred dock (native Plasma panel + 44OS plasmoid on KDE's task-manager model): pinned and running apps, hover magnification, running indicators, launch bounce, pin/unpin, intelligent hide |
| **44Launcher** | KRunner as a centred Spotlight-style search on **Super+Space**: apps, files (Baloo), settings, calculator, recent documents |
| **44Control** | Plasma's native tray applets in the menu bar: Wi-Fi/network, Bluetooth, volume and output, battery/power profiles, brightness and Night Light, notifications |
| **44Welcome** | First-login app (PyQt6/QML): appearance, wallpaper, effects, dock preferences, updates, system information, About |
| **44Theme** | NOVA colour schemes (dark default, light), 44NOVA window decoration, Nova and Horizon wallpapers, Inter font |
| **44Branding** | 44 logo family, Plymouth boot splash, Plasma splash, SDDM login screen, Calamares installer, About this System |

Details, limitations and design decisions: [docs/NOVA.md](docs/NOVA.md).

## Repository layout

| Path | Purpose |
| --- | --- |
| `build-44os.sh` | live-build driver (run as root on Debian trixie) |
| `config/package-lists/` | packages in the image |
| `config/includes.chroot/` | files copied into the image (desktop, branding, apps, defaults) |
| `config/hooks/live/` | chroot hooks: permissions, Calamares integration, branding checks, Plymouth |
| `branding/` | SVG sources and generators (`render.sh`, `colors.py`, `aurorae.py`, `plymouth.py`) for every committed asset |
| `scripts/verify-iso.sh` | static check of the ISO boot structures (BIOS + UEFI) |
| `scripts/check-qml.py`, `scripts/check-packages.sh` | build-time QML parse check, package availability check |
| `.github/scripts/` | VM test harness (QEMU/OVMF/VirtualBox, OCR-driven) |

## Build

GitHub Actions → **Build 44OS Live ISO** → *Run workflow* (or open a pull request).
The pipeline lints scripts/QML/packages, builds the ISO, verifies its boot
structures, then runs the runtime tests described in [docs/TESTING.md](docs/TESTING.md).
The ISO is uploaded as the `44OS-0.6-alpha-live-amd64` artifact (a zip
containing the `.iso` and `SHA256SUMS`).

Local build (Debian trixie, root): `sudo ./build-44os.sh` → `dist/`.

## Install in VirtualBox

1. Create a *Linux / Debian (64-bit)* VM with 4 GB RAM or more (8 GB
   recommended), 30 GB disk, and tick *Enable EFI*.
2. Extract the `.iso` from the downloaded zip and attach it to the optical drive.
3. Boot, choose **Live system**, then double-click **Install 44OS**.
4. After installation, remove the ISO from the optical drive and reboot.

VirtualBox without 3D acceleration renders with llvmpipe; 44OS detects this
and turns off blur and similar effects automatically (44Welcome → Appearance →
Visual effects lets you override it).

## Regenerating branding

```sh
sudo apt install librsvg2-bin imagemagick fonts-inter python3
branding/render.sh
```

## Licences

44OS code: GPL-2.0-or-later. 44OS artwork (logos, wallpapers, decoration,
splash): CC-BY-SA-4.0. 44OS ships Debian and KDE software under their own
licences; Debian and KDE are trademarks of their respective owners. No Apple
assets are used.
