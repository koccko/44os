# 44OS 0.4 Alpha

Built on Debian 13 + KDE Plasma 6 + Calamares. This is a **source bundle**, not an ISO.

## Changes
- Replaced large medical-looking cross and wallpaper slogan with a minimal abstract dark wallpaper.
- Added a compact geometric 44 symbol (SVG) and app icon.
- Top system bar, attempted content-sized centered floating dock (subject to Plasma scripting API compatibility).
- Kept Calamares; cleaned up duplicate Debian desktop installer launcher where its desktop entry uses `Name=Install Debian`.
- Rebranded SDDM wallpaper and launcher; kept accurate Debian origin in About This System (OS-release was intentionally not spoofed).

## Build
Copy this source tree into your GitHub repo preserving folders. GitHub Actions creates `44OS-0.4-alpha-live-amd64.iso` in the artifact.

## Test safely
Boot the new ISO in **Live** mode in VirtualBox. Check wallpaper, panel positions, installer icon, and SDDM (log out). **Do not reinstall** to test appearance.

## Limitations
This bundle is not yet boot-tested. KDE Plasma 6 scripting support for floating/fit panel properties varies; the dock may fall back to a full-width panel. `About this System` continues to identify Debian 13 accurately. Do not install over your existing working 44OS 0.2 until tested.
