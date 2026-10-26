#!/usr/bin/env bash
# 44OS live-desktop runtime test (QEMU + OVMF UEFI).
#
# Boots a serial-console copy of the ISO, waits for the Plasma session and
# checks/screenshots: 44Welcome first-login autostart, top bar, 44Dock (rest +
# hover magnification), launching an app from the dock, 44Launcher (KRunner,
# D-Bus and Super+Space), a decorated window, the global menu, About this
# System, and the 44Welcome system page. Writes $OUT/summary.txt with
# PASS/FAIL per check; exits non-zero if a required check fails.
#
# Usage: ISO=path OUT=dir desktop-test.sh
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ISO:?}" "${OUT:?}"
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
source "$HERE/vmlib.sh"
set +e   # keep going after a failed step; the summary decides

SUMMARY="$OUT/summary.txt"; : > "$SUMMARY"
FAILED=0
check() { # NAME REQUIRED(1/0) COMMAND...
  local name="$1" req="$2"; shift 2
  if "$@"; then echo "PASS  $name" >> "$SUMMARY"
  else
    if [[ "$req" == 1 ]]; then echo "FAIL  $name" >> "$SUMMARY"; FAILED=1
    else echo "WARN  $name" >> "$SUMMARY"; fi
  fi
}
crop() { convert "$OUT/$1.png" -crop "$2" +repage "$OUT/$3.png"; }

remaster_serial "$ISO" "$OUT/serial.iso"
VM_NAME=live FW=uefi VGA=virtio CDROM="$OUT/serial.iso" VARS="$OUT/live-vars.fd" MEM=4096 vm_start

check "GRUB menu (UEFI)" 1 wait_text 'Live system' 120 grub
key ret
check "Plasma session reaches graphical login (serial)" 1 ser_wait 'login: *$' 300
# Let Plasma finish starting (welcome autostart, panels, tray).
check "44Welcome opens automatically on first login" 1 wait_text 'Welcome to 44OS NOVA' 240 01-welcome-autostart
sleep 10; shot 01-welcome-autostart >/dev/null

check "serial login as live user" 1 ser_login user live
ser_define_gui
{
  echo "== 44osrc"; ser_run 'cat ~/.config/44osrc'
  echo "== kinfo"; ser_run 'kinfo 2>&1 | head -n 20'
  echo "== panels"; ser_run "grep -E '^\[|plugin=|launchers=|magnification=|iconSize=' ~/.config/plasma-org.kde.plasma.desktop-appletsrc | head -n 80"
  echo "== plasmashell panel geometry"; ser_run "grep -A3 -E 'Containments\]\[[0-9]+\]$' ~/.config/plasmashellrc | head -n 40"
  echo "== kwin decoration"; ser_run 'kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme; kreadconfig6 --file kwinrc --group Plugins --key blurEnabled; cat ~/.config/44osrc 2>/dev/null | grep -A3 Effects'
  echo "== plymouth"; ser_run 'plymouth-set-default-theme; cat /proc/cmdline'
  echo "== QML / plasmoid errors"; ser_run "journalctl --user -b --no-pager 2>/dev/null | grep -iE 'org\.44os|44os|qml.*(error|TypeError|ReferenceError|not installed)|file:///usr/share/plasma/plasmoids' | tail -n 60" 40
  echo "== autostart"; ser_run 'ls /etc/xdg/autostart | grep -iE "44os|calamares|welcome"'
} > "$OUT/diagnostics.txt" 2>&1
check "44Welcome completion persisted per user" 1 grep -q 'Completed=true' "$OUT/diagnostics.txt"
check "44Dock plasmoid in panel config" 1 grep -q 'plugin=org.44os.dock' "$OUT/diagnostics.txt"
check "Active-app plasmoid in panel config" 1 grep -q 'plugin=org.44os.activeapp' "$OUT/diagnostics.txt"
no_plasmoid_errors() { ! sed -n '/== QML/,/== autostart/p' "$OUT/diagnostics.txt" | grep -qE 'org\.44os.*(rror|TypeError|ReferenceError)'; }
check "No QML errors from 44OS plasmoids" 1 no_plasmoid_errors
check "44NOVA window decoration configured" 1 grep -q '__aurorae__svg__44NOVA' "$OUT/diagnostics.txt"
check "Plymouth theme is 44nova" 0 grep -qx '44nova' "$OUT/diagnostics.txt"

# Clean desktop: close the welcome window.
ser_run 'pkill -f /usr/share/44os/welcome/welcome.py; sleep 3' >/dev/null
shot 02-desktop >/dev/null      # refresh screen size
move $((SCREEN_W / 2)) $((SCREEN_H / 3)); sleep 3
shot 02-desktop >/dev/null
DOCK_GEOM="$((SCREEN_W / 2))x96+$((SCREEN_W / 4))+$((SCREEN_H - 96))"
crop 02-desktop "${SCREEN_W}x40+0+0" 02a-topbar
crop 02-desktop "$DOCK_GEOM" 02b-dock
check "Top bar shows clock/date" 1 ocr_has "$OUT/02a-topbar.png" '(Mon|Tue|Wed|Thu|Fri|Sat|Sun)|[0-9]{1,2}:[0-9]{2}'
check "Top bar shows active-app title" 0 ocr_has "$OUT/02a-topbar.png" 'Desktop'

# Dock hover magnification + tooltip, then launch an app from the dock.
move $((SCREEN_W / 2)) $((SCREEN_H - 34)); sleep 2
shot 03-dock-hover >/dev/null
crop 03-dock-hover "$DOCK_GEOM" 03a-dock-hover
check "Dock icons magnify under the pointer" 1 images_differ "$OUT/02b-dock.png" "$OUT/03a-dock-hover.png" 800
tooltip="$(ocr "$OUT/03-dock-hover.png" | grep -oiE 'Konsole|Firefox|Dolphin|Discover|System Settings|44Launcher' | head -n1 || true)"
echo "dock tooltip under pointer: ${tooltip:-none}" >> "$OUT/diagnostics.txt"
check "Dock tooltip shows the application name" 0 test -n "$tooltip"
click $((SCREEN_W / 2)) $((SCREEN_H - 34)); sleep 12
launched="$(ser_run 'pgrep -u "$(id -u)" -l -f "dolphin|firefox|konsole|plasma-discover|systemsettings|krunner" | grep -v pgrep')"
echo "== processes after dock click"$'\n'"$launched" >> "$OUT/diagnostics.txt"
check "Clicking a dock icon launches an application" 1 test -n "$launched"
shot 04-dock-launched >/dev/null
crop 04-dock-launched "$DOCK_GEOM" 04a-dock-running
ser_run 'pkill -u "$(id -u)" -f "dolphin|firefox-esr|konsole|plasma-discover|systemsettings"; sleep 2' >/dev/null

# 44Launcher via D-Bus (what the dock icon does) and via Super+Space.
ser_run "gui dbus-send --session --type=method_call --dest=org.kde.krunner /App org.kde.krunner.App.query string:'12*12'" >/dev/null
sleep 4
check "44Launcher (KRunner) opens and calculates" 1 wait_text '144' 20 05-launcher
key esc; sleep 2
key meta_l-spc; sleep 3
type_text "konsole"; sleep 3
check "Super+Space opens 44Launcher" 1 wait_text 'Konsole' 15 06-launcher-shortcut
key esc; sleep 2

# A decorated window (44NOVA Aurorae) and the global menu.
ser_run 'gui dolphin' >/dev/null
check "Dolphin window opens" 1 wait_text 'Home|Places|Dolphin' 40 07-window
sleep 3; shot 07-window >/dev/null
crop 07-window "${SCREEN_W}x40+0+0" 07a-topbar-globalmenu
check "Global menu shows the app's menus in the top bar" 0 ocr_has "$OUT/07a-topbar-globalmenu.png" 'File|Edit|View'
check "Active-app title follows the focused window" 0 ocr_has "$OUT/07a-topbar-globalmenu.png" 'Dolphin' 
ser_run 'pkill -u "$(id -u)" -x dolphin; sleep 2' >/dev/null

# About this System and 44Welcome's system page.
ser_run 'gui kinfocenter' >/dev/null
check "About this System shows 44OS branding" 1 wait_text '44OS' 60 08-about-system
ser_run 'pkill -u "$(id -u)" -x kinfocenter; sleep 2' >/dev/null
ser_run 'gui 44welcome --page system' >/dev/null
check "44Welcome system page opens" 1 wait_text 'Processor|Memory' 40 09-welcome-system
ser_run 'gui 44welcome --page appearance; sleep 1; pkill -f "welcome.py --page system"' >/dev/null
check "44Welcome appearance page opens" 0 wait_text 'Wallpaper' 30 10-welcome-appearance
ser_run 'pkill -f /usr/share/44os/welcome/welcome.py' >/dev/null

vm_stop
cat "$SUMMARY"
exit "$FAILED"
