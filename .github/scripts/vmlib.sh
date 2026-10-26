#!/usr/bin/env bash
# Shared helpers for 44OS VM tests (QEMU + OVMF, KVM when available).
#
#   vm_start        start a VM (see variables below), sets VM_PID
#   vm_stop         power off (QEMU quit)
#   vm_wait_exit S  wait up to S seconds for QEMU to exit (guest reboot with -no-reboot)
#   shot NAME       screenshot -> $OUT/NAME.png (prints path)
#   ocr PNG         OCR text of a screenshot
#   wait_text RE S [NAME]   wait until the screen shows text matching RE (case-insensitive)
#   click_text RE S         wait for RE on screen, then click its centre
#   click X Y | move X Y    absolute pointer in screen pixels (usb-tablet)
#   type_text STR           type via QEMU key events (US layout)
#   key COMBO               e.g. key ret, key ctrl-alt-f3
#   ser_wait RE S           wait for RE in the serial log (new output only)
#   ser_send LINE           type a line on the serial console
#
# Variables: OUT (results dir), VM_NAME, FW (uefi|bios), CDROM (iso path or empty),
#   DISKS (space-separated raw/qcow2 images, attached as virtio disks in order),
#   VARS (OVMF vars file to use/keep), MEM (MiB), VGA (std|virtio), NO_REBOOT (1 = exit on reboot)
set -Eeuo pipefail

: "${OUT:?OUT is required}"
mkdir -p "$OUT"
VM_NAME="${VM_NAME:-vm}"
SERIAL="$OUT/$VM_NAME-serial.log"
MON="$OUT/.$VM_NAME-mon.sock"
QMP="$OUT/.$VM_NAME-qmp.sock"
SER="$OUT/.$VM_NAME-ser.sock"
SER_POS=0

log() { echo "[$(date +%T)] $*" | tee -a "$OUT/test.log" >&2; }

vm_start() {
  local accel=(-accel tcg) fw=() media=() disks=() i=0
  [[ -w /dev/kvm ]] && accel=(-enable-kvm -cpu host)
  if [[ "${FW:-uefi}" == uefi ]]; then
    [[ -f "${VARS:?}" ]] || cp /usr/share/OVMF/OVMF_VARS_4M.fd "$VARS"
    fw=(-drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
        -drive if=pflash,format=raw,unit=1,file="$VARS")
  fi
  if [[ -n "${CDROM:-}" ]]; then
    media=(-drive file="$CDROM",media=cdrom,readonly=on,if=none,id=cd0 -device ide-cd,drive=cd0,bootindex=0)
  fi
  for d in ${DISKS:-}; do
    local fmt=raw; [[ "$d" == *.qcow2 ]] && fmt=qcow2
    disks+=(-drive file="$d",format="$fmt",if=none,id=disk$i,cache=unsafe
            -device virtio-blk-pci,drive=disk$i,bootindex=$((i + 1)))
    i=$((i + 1))
  done
  : > "$SERIAL"; SER_POS=0
  log "QEMU start $VM_NAME fw=${FW:-uefi} cdrom=${CDROM:-none} disks=${DISKS:-none}"
  qemu-system-x86_64 -machine q35 "${accel[@]}" -m "${MEM:-4096}" -smp 2 \
    "${fw[@]}" "${media[@]}" "${disks[@]}" \
    -vga "${VGA:-std}" -display none \
    -device qemu-xhci -device usb-tablet \
    -chardev socket,id=ser0,path="$SER",server=on,wait=off,logfile="$SERIAL" -serial chardev:ser0 \
    -monitor unix:"$MON",server,nowait -qmp unix:"$QMP",server,nowait \
    -nic user,model=virtio-net-pci -device virtio-rng-pci \
    ${NO_REBOOT:+-no-reboot} \
    >"$OUT/$VM_NAME-qemu.log" 2>&1 &
  VM_PID=$!
  sleep 2
}

hmp() { echo "$*" | socat - UNIX-CONNECT:"$MON" >/dev/null 2>&1; }
qmp() { printf '{"execute":"qmp_capabilities"}\n%s\n' "$1" | socat -t2 - UNIX-CONNECT:"$QMP" >/dev/null 2>&1; }
vm_alive() { kill -0 "$VM_PID" 2>/dev/null; }
vm_stop() { hmp quit || kill "$VM_PID" 2>/dev/null || true; sleep 2; }
vm_wait_exit() {
  local end=$(( $(date +%s) + $1 ))
  while vm_alive; do (( $(date +%s) > end )) && return 1; sleep 3; done
  return 0
}

SCREEN_W=1280; SCREEN_H=800
shot() {
  local png="$OUT/$1.png"
  hmp "screendump $OUT/.shot.ppm" || return 1
  sleep 1
  convert "$OUT/.shot.ppm" "$png" 2>/dev/null || return 1
  rm -f "$OUT/.shot.ppm"
  identify -format '%w %h' "$png" > "$OUT/.dims"
  read -r SCREEN_W SCREEN_H < "$OUT/.dims"
  echo "$png"
}

ocr_has() { ocr "$1" | grep -qiE "$2"; }          # FILE RE
images_differ() { # A B [MIN_PIXELS]: true when at least MIN_PIXELS pixels differ
  local n; n="$(compare -metric AE -fuzz 8% "$1" "$2" null: 2>&1 || true)"
  n="${n%% *}"; [[ "${n%.*}" =~ ^[0-9]+$ ]] && (( ${n%.*} >= ${3:-500} ))
}

# OCR helpers: upscale for accuracy; word boxes are mapped back to screen pixels.
ocr() { convert "$1" -resize 200% -colorspace Gray "$OUT/.ocr.png"; tesseract "$OUT/.ocr.png" - 2>/dev/null; }
ocr_tsv() { convert "$1" -resize 200% -colorspace Gray "$OUT/.ocr.png"; tesseract "$OUT/.ocr.png" - tsv 2>/dev/null; }

# find_text PNG REGEX -> "x y" centre (screen px) of the first line whose text matches
find_text() {
  ocr_tsv "$1" | python3 -c '
import sys, re, collections
pat = re.compile(sys.argv[1], re.I)
lines = collections.OrderedDict()
for row in sys.stdin.read().splitlines()[1:]:
    c = row.split("\t")
    if len(c) < 12 or not c[11].strip(): continue
    key = (c[2], c[3], c[4])
    lines.setdefault(key, []).append((c[11], int(c[6]), int(c[7]), int(c[8]), int(c[9])))
for words in lines.values():
    text = " ".join(w[0] for w in words)
    m = pat.search(text)
    if not m: continue
    # pick the words covering the match
    pos = 0; sel = []
    for w in words:
        start, end = pos, pos + len(w[0])
        if end > m.start() and start < m.end(): sel.append(w)
        pos = end + 1
    sel = sel or words
    x0 = min(w[1] for w in sel); y0 = min(w[2] for w in sel)
    x1 = max(w[1] + w[3] for w in sel); y1 = max(w[2] + w[4] for w in sel)
    print((x0 + x1) // 4, (y0 + y1) // 4)
    break
' "$2"
}

wait_text() { # RE SECONDS [NAME]
  local re="$1" end=$(( $(date +%s) + $2 )) name="${3:-wait}" png
  while (( $(date +%s) < end )); do
    vm_alive || { log "VM exited while waiting for /$re/"; return 1; }
    png="$(shot "$name")" || { sleep 3; continue; }
    if ocr "$png" | tr '\n' ' ' | grep -qiE "$re"; then log "screen shows /$re/"; return 0; fi
    sleep 4
  done
  log "timeout waiting for /$re/"; return 1
}

screen_dims() { [[ -f "$OUT/.dims" ]] && read -r SCREEN_W SCREEN_H < "$OUT/.dims"; true; }
move() { # X Y in screen pixels -> absolute tablet coordinates
  screen_dims
  local ax=$(( $1 * 32767 / SCREEN_W )) ay=$(( $2 * 32767 / SCREEN_H ))
  qmp "{\"execute\":\"input-send-event\",\"arguments\":{\"events\":[{\"type\":\"abs\",\"data\":{\"axis\":\"x\",\"value\":$ax}},{\"type\":\"abs\",\"data\":{\"axis\":\"y\",\"value\":$ay}}]}}"
}
click() {
  move "$1" "$2"; sleep 0.3
  qmp '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":true,"button":"left"}}]}}'
  sleep 0.15
  qmp '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":false,"button":"left"}}]}}'
}

click_text() { # RE SECONDS
  local re="$1" end=$(( $(date +%s) + $2 )) png xy
  while (( $(date +%s) < end )); do
    vm_alive || return 1
    png="$(shot click)" || { sleep 3; continue; }
    xy="$(find_text "$png" "$re")"
    if [[ -n "$xy" ]]; then log "click /$re/ at $xy"; click $xy; sleep 1; return 0; fi
    sleep 3
  done
  log "timeout: could not find /$re/ to click"; return 1
}

key() { hmp "sendkey $1"; sleep 0.25; }
type_text() {
  local s="$1" i ch k
  for (( i = 0; i < ${#s}; i++ )); do
    ch="${s:i:1}"
    case "$ch" in
      [a-z0-9]) k="$ch" ;;
      [A-Z]) k="shift-${ch,,}" ;;
      ' ') k=spc ;; '-') k=minus ;; '_') k=shift-minus ;; '.') k=dot ;; ',') k=comma ;;
      '/') k=slash ;; '=') k=equal ;; '+') k=shift-equal ;; ':') k=shift-semicolon ;;
      ';') k=semicolon ;; '!') k=shift-1 ;; '@') k=shift-2 ;; '#') k=shift-3 ;; '$') k=shift-4 ;;
      '%') k=shift-5 ;; '&') k=shift-7 ;; '*') k=shift-8 ;; '(') k=shift-9 ;; ')') k=shift-0 ;;
      '|') k=shift-backslash ;; '>') k=shift-dot ;; '<') k=shift-comma ;; '"') k=shift-apostrophe ;;
      "'") k=apostrophe ;; '~') k=shift-grave_accent ;;
      *) log "type_text: unsupported character"; continue ;;
    esac
    hmp "sendkey $k"; sleep 0.06
  done
}

ser_wait() { # RE SECONDS — only output written after the last ser_wait/ser_send counts
  local re="$1" end=$(( $(date +%s) + $2 ))
  while (( $(date +%s) < end )); do
    if tail -c +"$((SER_POS + 1))" "$SERIAL" | tr -d '\r' | grep -qaE "$re"; then
      SER_POS=$(stat -c %s "$SERIAL"); return 0
    fi
    vm_alive || return 1
    sleep 2
  done
  return 1
}
ser_send() { SER_POS=$(stat -c %s "$SERIAL"); printf '%s\r' "$1" | socat -u - UNIX-CONNECT:"$SER" >/dev/null 2>&1 || true; }
# ser_run CMD [SECONDS]: run a shell command on a logged-in serial console, capture its output
ser_run() {
  local tag="R$RANDOM$RANDOM" t="${2:-30}"
  ser_send "echo ${tag}B; $1; echo ${tag}E"
  ser_wait "^${tag}E" "$t" || true
  tr -d '\r' < "$SERIAL" | sed -n "/^${tag}B\$/,/^${tag}E\$/p" | sed '1d;$d'
}

# remaster_serial ISO OUT_ISO: test copy whose live kernel also logs to ttyS0
# (serial login available). Boot images are replayed unchanged.
remaster_serial() {
  local iso="$1" out="$2" work="$OUT/.remaster" maps=() f
  rm -rf "$work"; mkdir -p "$work"
  for d in /boot/grub /isolinux; do osirrox -indev "$iso" -extract "$d" "$work$d" >/dev/null 2>&1 || true; done
  chmod -R u+w "$work"
  while IFS= read -r -d '' f; do
    if grep -q 'boot=live' "$f"; then
      sed -i -E '/boot=live/ s/boot=live/boot=live console=tty0 console=ttyS0,115200n8/' "$f"
      maps+=(-map "$f" "${f#"$work"}")
    fi
  done < <(find "$work" -type f -name '*.cfg' -print0)
  xorriso -indev "$iso" -outdev "$out" -boot_image any replay "${maps[@]}" -commit >"$OUT/remaster.log" 2>&1
  rm -rf "$work"
}

# Serial login on a getty (ttyS0). Returns non-zero if the login is rejected.
ser_login() { # USER PASSWORD
  local i
  for i in 1 2 3; do
    ser_send ""
    ser_wait 'login: *$' 20 && break
  done
  ser_send "$1"
  ser_wait 'Password: *$' 20 || return 1
  SER_POS=$(stat -c %s "$SERIAL"); printf '%s\r' "$2" | socat -u - UNIX-CONNECT:"$SER" >/dev/null 2>&1
  if ser_wait '[$#] *$|Login incorrect' 40; then
    tail -c 400 "$SERIAL" | tr -d '\r' | grep -q 'Login incorrect' && return 1
    ser_send 'stty cols 220 -echo; export PAGER=cat SYSTEMD_PAGER=cat PS1="$ "'
    sleep 2
    return 0
  fi
  return 1
}

# Define gui() in the serial shell: runs a program inside the user's graphical session.
ser_define_gui() {
  ser_send 'gui() { pid=$(pgrep -u "$(id -u)" -x plasmashell | head -n1); env $(tr "\0" "\n" < /proc/$pid/environ | grep -E "^(WAYLAND_DISPLAY|DISPLAY|XAUTHORITY|XDG_RUNTIME_DIR|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|XDG_DATA_DIRS|KDE_FULL_SESSION|KDE_SESSION_VERSION|QT_QPA_PLATFORMTHEME|DBUS_SESSION_BUS_ADDRESS|LANG)=") setsid -f "$@" >/dev/null 2>&1; }'
  sleep 1
}
