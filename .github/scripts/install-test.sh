#!/usr/bin/env bash
# 44OS installation lifecycle test (QEMU + OVMF UEFI).
#
#  1. Boot the live ISO, start the installer the way a user does
#     ("Install 44OS" → calamares-install-debian → pkexec calamares).
#  2. Drive Calamares with OCR + mouse/keyboard: erase the first disk,
#     create a user with a random password (never written to logs).
#  3. Reboot WITHOUT the ISO; log in on SDDM (graphical) → Plasma desktop,
#     44Welcome appears on this first login.
#  4. TTY login (Ctrl+Alt+F3): id, hostname, root device, no live medium,
#     kernel command line; change the password with passwd; old password is
#     rejected, new password works.
#  5. Reboot again; SDDM login with the new password; 44Welcome does not
#     reappear (per-user completion persisted).
#  6. Boot with a fresh NVRAM (removable-media fallback path).
#  7. A second "canary" disk attached during install must be bit-identical.
#
# Usage: ISO=path OUT=dir install-test.sh
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ISO:?}" "${OUT:?}"
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
source "$HERE/vmlib.sh"
set +e   # keep going after a failed step; the summary decides

SUMMARY="$OUT/summary.txt"; : > "$SUMMARY"
FAILED=0
check() {
  local name="$1" req="$2"; shift 2
  if "$@"; then echo "PASS  $name" >> "$SUMMARY"
  else
    if [[ "$req" == 1 ]]; then echo "FAIL  $name" >> "$SUMMARY"; FAILED=1
    else echo "WARN  $name" >> "$SUMMARY"; fi
  fi
}
finish() { vm_stop 2>/dev/null; cat "$SUMMARY"; exit "$FAILED"; }

FULLNAME="Nova Tester"
LOGIN="nova"
# Random throwaway credentials for the test VM; never echoed or logged.
PASS1="Nova$(openssl rand -hex 4)x"
PASS2="Lumen$(openssl rand -hex 4)y"

qemu-img create -q -f qcow2 "$OUT/target.qcow2" 24G
# Canary: an unrelated disk with a filesystem and a marker file.
truncate -s 256M "$OUT/canary.img"
mkfs.ext4 -q -F -L CANARY "$OUT/canary.img"
CANARY_SUM_BEFORE="$(sha256sum "$OUT/canary.img" | cut -d' ' -f1)"

remaster_serial "$ISO" "$OUT/serial.iso"

# --------------------------------------------------------------------------
# 1. Live session, start the installer
VM_NAME=live FW=uefi VGA=std CDROM="$OUT/serial.iso" DISKS="$OUT/target.qcow2 $OUT/canary.img" \
  VARS="$OUT/vars.fd" MEM=4096 NO_REBOOT=1 vm_start
check "Live ISO: GRUB menu" 1 wait_text 'Live system' 120 grub || finish
key ret
check "Live ISO: session started" 1 ser_wait 'login: *$' 300 || finish
wait_text 'Welcome to 44OS NOVA|Install 44OS' 240 live-desktop
sleep 10
check "Live ISO: serial login" 1 ser_login user live || finish
ser_define_gui
ser_run 'pkill -f /usr/share/44os/welcome/welcome.py' >/dev/null
ser_run 'lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL' > "$OUT/lsblk-before.txt"

# The real launcher used by the desktop icon.
ser_run 'grep -E "^(Exec|TryExec)=" ~/Desktop/44os-install.desktop /usr/share/applications/44os-install.desktop' > "$OUT/launcher.txt"
check "Live desktop has exactly one installer launcher" 1 bash -c "[ \"\$(grep -c 'Exec=calamares-install-debian' '$OUT/launcher.txt')\" -ge 1 ]"
ser_run 'gui calamares-install-debian' >/dev/null
# pkexec may ask the live user for the password ("live").
for i in $(seq 1 30); do
  png="$(shot calamares-start)"
  txt="$(ocr "$png")"
  if grep -qiE 'Authentication|Password' <<<"$txt" && ! grep -qiE 'Welcome to' <<<"$txt"; then
    type_text live; key ret; sleep 4
  fi
  grep -qiE 'Welcome to the|Welcome to 44OS NOVA' <<<"$txt" && break
  sleep 3
done
check "Calamares starts from the Install 44OS launcher" 1 wait_text 'Welcome to the|installer' 60 cal-01-welcome || finish

# --------------------------------------------------------------------------
# 2. Drive Calamares
check "Calamares: welcome → location" 1 click_text '^Next$|Next' 30
check "Calamares: location → keyboard" 1 wait_text 'Location|Region|Zone|Time' 60 cal-02-location
click_text 'Next' 30
check "Calamares: keyboard page" 1 wait_text 'Keyboard' 60 cal-03-keyboard
click_text 'Next' 30
check "Calamares: partition page" 1 wait_text 'Erase disk|Manual partitioning' 120 cal-04-partitions || finish
check "Calamares: first disk (/dev/vda) selected as target" 1 ocr_has "$OUT/cal-04-partitions.png" 'vda'
check "Calamares: choose Erase disk" 1 click_text 'Erase disk' 30
sleep 4; shot cal-05-erase >/dev/null
click_text 'Next' 30
check "Calamares: users page" 1 wait_text 'What is your name|Your Full Name' 60 cal-06-users || finish
if xy="$(find_text "$OUT/cal-06-users.png" 'Full Name')" && [[ -n "$xy" ]]; then click $xy
else xy="$(find_text "$OUT/cal-06-users.png" 'What is your name')"; read -r x y <<<"$xy"; click "$x" $((y + 34)); fi
type_text "$FULLNAME"; sleep 2
shot cal-07-name >/dev/null
for label in 'Choose Password' 'Repeat Password'; do
  xy="$(find_text "$OUT/cal-07-name.png" "$label")"
  if [[ -n "$xy" ]]; then click $xy; type_text "$PASS1"; sleep 1; fi
done
sleep 2; shot cal-08-users-filled >/dev/null
ocr "$OUT/cal-08-users-filled.png" > "$OUT/cal-08-users.txt"
check "Calamares: login name derived from full name" 0 grep -qiE '\bnova\b' "$OUT/cal-08-users.txt"
click_text 'Next' 30
check "Calamares: summary page" 1 wait_text 'Summary|Install' 60 cal-09-summary || finish
check "Calamares: summary shows erase of /dev/vda only" 0 bash -c "grep -q vda <(tesseract '$OUT/cal-09-summary.png' - 2>/dev/null) && ! grep -q vdb <(tesseract '$OUT/cal-09-summary.png' - 2>/dev/null)"
click_text '^Install$|Install' 30
sleep 3
check "Calamares: confirm Install now" 1 click_text 'Install now' 30
end=$(( $(date +%s) + 2700 )); result=""
while (( $(date +%s) < end )); do
  png="$(shot cal-10-progress)"; txt="$(ocr "$png")"
  if grep -qiE 'All done|has been installed|Installation Complete' <<<"$txt"; then result=ok; break; fi
  if grep -qiE 'Installation Failed|Error' <<<"$txt"; then result=failed; break; fi
  sleep 20
done
shot cal-11-finished >/dev/null
ser_run 'sudo tail -n 200 /root/.cache/calamares/session.log 2>/dev/null || sudo find / -name session.log -path "*calamares*" -exec tail -n 200 {} \; 2>/dev/null' 60 \
  | grep -viE 'password' > "$OUT/calamares-session.log"
check "Calamares: installation completes" 1 test "$result" = ok || finish
# Finished page: "Restart now" is checked by default; Done reboots (QEMU exits: -no-reboot).
click_text 'Done' 30
vm_wait_exit 180 || vm_stop

CANARY_SUM_AFTER="$(sha256sum "$OUT/canary.img" | cut -d' ' -f1)"
check "Unrelated disk untouched by the installer (bit-identical)" 1 test "$CANARY_SUM_BEFORE" = "$CANARY_SUM_AFTER"

# --------------------------------------------------------------------------
# 3. First boot from disk, no ISO attached
sddm_login() { # PASSWORD SHOTNAME
  wait_text "$FULLNAME|Password|$LOGIN" 300 "$2-greeter" || return 1
  sleep 3
  type_text "$1"; key ret
  # The greeter disappears and Plasma starts.
  wait_text 'Desktop|Welcome to 44OS NOVA|[0-9]{1,2}:[0-9]{2}' 180 "$2-session"
}
VM_NAME=disk1 FW=uefi VGA=std CDROM="" DISKS="$OUT/target.qcow2 $OUT/canary.img" VARS="$OUT/vars.fd" NO_REBOOT=1 vm_start
check "Installed system boots without the ISO (GRUB → SDDM)" 1 wait_text "$FULLNAME|Password|$LOGIN" 300 disk1-01-sddm || finish
check "SDDM login with the installer-set password" 1 sddm_login "$PASS1" disk1-02 || finish
check "44Welcome appears on the first login" 1 wait_text 'Welcome to 44OS NOVA' 120 disk1-03-welcome
sleep 15; shot disk1-04-desktop >/dev/null

# --------------------------------------------------------------------------
# 4. TTY authentication, system facts, password change
tty_login() { # USER PASSWORD SHOTNAME -> 0 if a shell prompt appears
  key ctrl-alt-f3; sleep 3
  wait_text 'login:' 30 "$3-a" || return 1
  type_text "$1"; key ret; sleep 2
  wait_text 'Password' 20 "$3-b" || return 1
  type_text "$2"; key ret; sleep 5
  shot "$3-c" >/dev/null
  ocr "$OUT/$3-c.png" | grep -qiE "$1@" && ! ocr "$OUT/$3-c.png" | tail -n 3 | grep -qi 'incorrect'
}
check "TTY login (Ctrl+Alt+F3) with the installer-set password" 1 tty_login "$LOGIN" "$PASS1" tty-01
type_text "clear; id; hostname; findmnt -n -o SOURCE,FSTYPE /; test -d /run/live && echo LIVE-MEDIUM || echo NO-LIVE-MEDIUM; cat /proc/cmdline; grep -E '^(NAME|VERSION|CODENAME)=' /etc/44os-release"; key ret; sleep 4
shot tty-02-facts >/dev/null; ocr "$OUT/tty-02-facts.png" > "$OUT/tty-facts.txt"
check "Installed user has uid 1000 and is in sudo group" 1 grep -qiE 'uid=1000\(nova\).*sudo' "$OUT/tty-facts.txt"
check "Root filesystem is the installed disk (vda)" 1 grep -qiE '/dev/vda' "$OUT/tty-facts.txt"
check "No live medium in the installed system" 1 grep -q 'NO-LIVE-MEDIUM' "$OUT/tty-facts.txt"
check "Installed kernel command line has no boot=live" 1 bash -c "! grep -q 'boot=live' '$OUT/tty-facts.txt'"
check "Installed system identifies as 44OS 0.6" 0 grep -qiE '0\.6' "$OUT/tty-facts.txt"
type_text "clear; passwd"; key ret; sleep 2
wait_text 'Current password' 15 tty-03-passwd; type_text "$PASS1"; key ret; sleep 2
wait_text 'New password' 15 tty-04-passwd; type_text "$PASS2"; key ret; sleep 2
wait_text 'Retype' 15 tty-05-passwd; type_text "$PASS2"; key ret; sleep 3
check "passwd changes the password" 1 wait_text 'updated successfully' 15 tty-06-passwd
type_text "exit"; key ret; sleep 3
wait_text 'login:' 30 tty-07
type_text "$LOGIN"; key ret; sleep 2; wait_text 'Password' 20 tty-08; type_text "$PASS1"; key ret; sleep 6
shot tty-09-oldpw >/dev/null
check "Old password is rejected after the change" 1 ocr_has "$OUT/tty-09-oldpw.png" 'incorrect'
# Login again with the new password (agetty shows login: again after a failure).
sleep 3
type_text "$LOGIN"; key ret; sleep 2; wait_text 'Password' 20 tty-10; type_text "$PASS2"; key ret; sleep 5
shot tty-11-newpw >/dev/null
check "New password works on the TTY" 1 ocr_has "$OUT/tty-11-newpw.png" "$LOGIN@"
type_text "systemctl reboot"; key ret
vm_wait_exit 120 || vm_stop

# --------------------------------------------------------------------------
# 5. Reboot persistence: new password on SDDM, no second welcome
VM_NAME=disk2 FW=uefi VGA=std CDROM="" DISKS="$OUT/target.qcow2" VARS="$OUT/vars.fd" NO_REBOOT=1 vm_start
check "Second boot reaches SDDM" 1 wait_text "$FULLNAME|Password|$LOGIN" 300 disk2-01-sddm
check "SDDM login with the changed password after reboot" 1 sddm_login "$PASS2" disk2-02
sleep 45; shot disk2-03-desktop >/dev/null
check "44Welcome does not reappear on later logins" 1 bash -c "! tesseract '$OUT/disk2-03-desktop.png' - 2>/dev/null | grep -qi 'Welcome to 44OS NOVA'"
vm_stop

# --------------------------------------------------------------------------
# 6. Fresh NVRAM: firmware must find the removable-media fallback loader
VM_NAME=disk3 FW=uefi VGA=std CDROM="" DISKS="$OUT/target.qcow2" VARS="$OUT/vars-fresh.fd" vm_start
check "Boots with empty NVRAM (EFI/BOOT/BOOTX64.EFI fallback)" 0 wait_text "$FULLNAME|Password|$LOGIN" 300 disk3-01-sddm
finish
