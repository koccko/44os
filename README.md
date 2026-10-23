# 44OS 0.3 Alpha — Petrol Copper Edition

Debian 13 / KDE Plasma 6 Live ISO with Calamares installer.

## Changes from 0.2
- 44OS SVG wallpaper and Petrol Copper KDE color scheme
- One-time KDE Plasma panel setup: top system bar and bottom icon task manager (dock-like panel)
- 44OS first-login autostart for Live and installed users
- SDDM Breeze wallpaper override and GRUB distributor label
- Additional Install 44OS launcher (the original Debian installer launcher may remain)
- Same working Debian Calamares configuration as 0.2

## Build
Commit these files to the GitHub repository, then run the Build 44OS Live ISO workflow.
Download the Actions artifact ZIP, extract the ISO, and boot it in VirtualBox.

## Test checklist
1. Boot ISO in VirtualBox, verify wallpaper, colors and panels. The one-time setup may take up to 50 seconds after login.
2. Open Install 44OS and verify Calamares launches. If pkexec launch fails, use the original Install Debian icon.
3. Install to an EMPTY VirtualBox virtual disk only.
4. Shut down, eject ISO, boot from virtual disk.
5. Verify wallpaper, colors, panels and installer boot behavior.

## Known limitations
- Not yet tested in CI for boot or Calamares execution; CI checks ISO generation only.
- Panel layout uses Plasma DBus scripting; if the scripting API differs, appearance may need a follow-up fix.
- The bottom panel is dock-like, not a fully floating macOS-style dock.
- Login theme is Breeze with a 44OS wallpaper; not yet a fully custom QML SDDM theme.
- The original Debian Calamares launcher/branding may remain; do not modify Calamares core until validated.
- System remains Debian-based and /etc/os-release accurately reports Debian.
- Do not deploy to a real disk before testing in a VM and taking backups.
