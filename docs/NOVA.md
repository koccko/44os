# 44OS NOVA: design and implementation

NOVA is built from native KDE Plasma 6 and Qt pieces wherever they exist.
44OS code only fills gaps that Plasma does not cover (dock magnification,
the active-application title, the welcome app), and every piece degrades
to stock Plasma behaviour if it fails.

## NOVA Glass design system

| Token | Colour | Used for |
| --- | --- | --- |
| Primary background | `#080D18` | views, desktop, splash, Plymouth |
| Secondary background | `#111A2B` | windows, title bars, headers |
| Floating surfaces | `#18243A` | buttons, tooltips, cards |
| Primary accent | `#65A8FF` | selection, focus, indicators, links |
| Secondary accent | `#8B7CFF` | visited links, gradients |
| Primary text | `#F1F5FF` | |
| Secondary text | `#A7B5CC` | inactive text |
| Borders | `#344765` | decoration border, cards, entry fields |
| Success | `#49D9AD` | positive text, maximize button |
| Warning | `#FFBE70` | neutral text, minimize button |

All colour files are generated from one palette in `branding/colors.py`
(`44OSNova.colors`, `44OSNovaLight.colors`, `/etc/xdg/kdeglobals`).
Translucency and blur come from Plasma's own panel opacity and KWin's blur
effect, so they turn off cleanly when not supported.

## Components

### Menu bar (top panel)
`kickoff` (44 symbol) · `org.44os.activeapp` · `org.kde.plasma.appmenu` · spacer ·
`org.kde.plasma.systemtray` · `org.kde.plasma.digitalclock`.

* **Global menu.** KDE/Qt applications export their menus to the menu bar
  through Plasma's appmenu protocol and hide the in-window menu bar.
  **Fallback:** applications that don't support it (Firefox, most GTK apps) keep
  their own in-window menus; the active-application title still shows their name.
* **Active application** (`org.44os.activeapp`): bold name of the focused
  application from KDE's task-manager model; "Desktop" when nothing is focused.

### 44Dock
A floating, centred, content-sized Plasma panel (intelligent hide = Plasma's
"dodge windows") containing the `org.44os.dock` plasmoid.

* Uses `org.kde.taskmanager` (the same model as Plasma's task managers):
  launching, activation, minimise toggle, window grouping per application,
  cycling through an application's windows, middle-click for a new instance.
* Running indicators (one dot per window, max two; accent colour when active),
  launch bounce, attention bounce, tooltips.
* Context menu (New Window, Keep in Dock / Remove from Dock, Close); drop a
  `.desktop` file on the dock to pin it. The menu is created on demand, so a menu
  problem can never break the dock itself.
* **Magnification:** icons near the pointer grow (cosine falloff) and push
  their neighbours apart; the dock reserves the extra width so the panel doesn't
  resize while you hover. **Limitation:** Plasma clips widgets to their panel,
  so icons can only grow into the dock's own height (≈1.3× with the default
  72 px dock and 44 px icons), not above it as on macOS. Configurable
  (0–100 %, capped by the panel height) in the widget settings and in 44Welcome.
* Not implemented in 0.6: drag-and-drop reordering of icons, badges.
* **Fallback:** 44Welcome → Dock → Style → *Classic* swaps in Plasma's own
  icon-only task manager with the same pinned launchers.

### 44Launcher
KRunner with `FreeFloating=true` (centred), bound to **Super+Space** (Alt+Space
and Alt+F2 keep working), also pinned as the first dock item. Search plugins:
applications, files (Baloo, where indexing is enabled), System Settings,
calculator, unit converter, recent documents, windows.

### 44Control (quick settings)
Plasma's native system-tray applets: Networks (Wi-Fi), Bluetooth, Audio Volume
(output device + volume), Power and Battery (power profiles), Brightness and
Color (brightness where supported, Night Light), Notifications (Do Not
Disturb). Only controls the hardware supports are shown. No custom toggles are
faked.

### Window management
* **44NOVA** Aurorae decoration (`branding/aurorae.py`): glass title bar,
  rounded top corners, soft shadow, thin border, orb buttons on the left whose
  glyphs appear on hover. Colours are 44OS's own, not Apple's.
* KWin: Magic Lamp minimise, Overview (Meta+W, top-left hot corner), thumbnail-
  grid Alt+Tab, four virtual desktops, blur.
* **Performance:** `/usr/libexec/44os/session-setup` asks KWin which OpenGL
  renderer it uses. On software rendering (llvmpipe, e.g. VirtualBox without 3D)
  it switches blur, background contrast and Magic Lamp off for that user, and back
  on when a GPU is detected later. 44Welcome can pin *Full* or *Reduced*.

### 44Welcome
`/usr/bin/44welcome` (PyQt6 + QtQuick, `/usr/share/44os/welcome`).
* Starts automatically on a user's **first** login
  (`/etc/xdg/autostart/org.44os.welcome-autostart.desktop` → `44welcome --autostart`).
  As soon as it has been shown it writes `~/.config/44osrc` `[Welcome] Completed=true`,
  so it never autostarts again for that user. Reopen it from the application
  menu (*44Welcome*).
* Pages: Welcome (*Welcome to 44OS NOVA — Your system. Your rules.*),
  Appearance (NOVA Dark/Light, wallpapers, visual effects), Dock (visibility,
  style, magnification; applied live through PlasmaShell scripting), Updates
  (Discover; Install 44OS in the live session), System (hardware and software
  versions from `kinfo` and `/proc`), About.
* `44welcome --snapshot DIR` renders every page to PNG (used for docs and tests).

### Branding
* Logo: two parallel-diagonal "4"s sharing one crossbar (`branding/src`).
* Plymouth `44nova` (two-step: breathing glow around the mark; password and
  keyboard-layout prompts for encrypted installs), Plasma startup splash,
  SDDM Breeze greeter with the Nova wallpaper, NOVA lock-up and default avatar
  (session selection, keyboard layout indicator and power buttons are the
  greeter's own), Calamares branding, *About this System* (`kcm-about-distrorc`).
* `/etc/os-release` stays Debian on purpose (package tooling relies on it);
  44OS identity lives in `/etc/44os-release`.

## Installer
Debian's Calamares configuration is unchanged apart from branding and the launcher:
* One launcher, *Install 44OS* → `calamares-install-debian` (Debian's wrapper:
  pkexec, Wayland access, stale fstab), shown only in the live session.
* `bootloaderEntryName: Debian` keeps Debian's signed shim/GRUB layout; Calamares
  also installs the removable-media fallback loader.
* Partitioning, users (password hashing via Calamares' users module), locale,
  keyboard and bootloader are Debian's tested modules.
* Dual boot: Calamares offers *Install alongside* / *Replace a partition* /
  *Manual* when it finds other systems. 44OS has **not** been tested with
  Windows dual boot yet; see docs/STATUS.md.

## Known limitations (0.6)
* Dock magnification is limited to the dock's height (see above); no drag
  reordering yet.
* Global menu only for applications that support KDE's appmenu protocol.
* Panels are created on the primary screen; additional screens get the
  wallpaper but no extra menu bar or dock (add them with *Add Panel* if wanted).
* The live boot menu (GRUB/isolinux) still uses live-build's default artwork.
