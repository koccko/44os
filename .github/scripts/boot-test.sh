#!/usr/bin/env bash
# 44OS automated boot test.
#
# Boots an ISO headless in QEMU (OVMF UEFI, OVMF UEFI + Secure Boot, or
# SeaBIOS) or in VirtualBox (EFI), takes periodic screenshots, OCRs them, and
# captures the serial console. Results are written to $OUT/result.txt.
#
# Stages detected:
#   grub       firmware found the boot image and GRUB drew its menu
#   kernel     the Linux kernel / systemd reached userspace (serial)
#   graphical  systemd reached graphical.target (serial)
#
# Environment:
#   ISO         path to the ISO (required)
#   NAME        label for this run                        (default: test)
#   HV          qemu | vbox                               (default: qemu)
#   FW          uefi | uefi-sb | bios                     (default: uefi)
#   MEDIA       cdrom | usb                               (default: cdrom)
#   DURATION    seconds to run                            (default: 300)
#   REQUIRE     grub | kernel | graphical | none          (default: grub)
#   SERIAL_ISO  1 = remaster a copy whose kernel/GRUB also log to ttyS0
#   OUT         output directory                          (default: boot-$NAME)
set -Eeuo pipefail

ISO="${ISO:?ISO is required}"
NAME="${NAME:-test}"
HV="${HV:-qemu}"
FW="${FW:-uefi}"
MEDIA="${MEDIA:-cdrom}"
DURATION="${DURATION:-300}"
REQUIRE="${REQUIRE:-grub}"
SERIAL_ISO="${SERIAL_ISO:-0}"
OUT="${OUT:-$PWD/boot-$NAME}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
ISO="$(readlink -f "$ISO")"

log() { echo "[$(date +%T)] $*" | tee -a "$OUT/test.log"; }

# --------------------------------------------------------------------------
# Optional: make a test copy of the ISO with serial console enabled. The boot
# images (El Torito BIOS + EFI, MBR/GPT system area) are replayed unchanged,
# so the firmware -> GRUB path being tested is identical to the original.
# --------------------------------------------------------------------------
if [[ "$SERIAL_ISO" == 1 ]]; then
  work="$OUT/remaster"; rm -rf "$work"; mkdir -p "$work"
  for d in /boot/grub /isolinux; do
    osirrox -indev "$ISO" -extract "$d" "$work$d" >/dev/null 2>&1 || true
  done
  chmod -R u+w "$work"
  maps=()
  while IFS= read -r -d '' f; do
    if grep -q 'boot=live' "$f"; then
      sed -i -E \
        -e '/boot=live/ s/ (quiet|splash)\b//g' \
        -e '/boot=live/ s/boot=live/boot=live console=tty0 console=ttyS0,115200n8 systemd.show_status=1/' \
        "$f"
      maps+=(-map "$f" "${f#"$work"}")
    fi
  done < <(find "$work" -type f -name '*.cfg' -print0)
  if [[ -f "$work/boot/grub/grub.cfg" ]]; then
    { printf 'serial --unit=0 --speed=115200\nterminal_input --append serial\nterminal_output --append serial\n'
      cat "$work/boot/grub/grub.cfg"; } > "$work/grub.cfg.new"
    mv "$work/grub.cfg.new" "$work/boot/grub/grub.cfg"
    maps+=(-map "$work/boot/grub/grub.cfg" /boot/grub/grub.cfg)
  fi
  log "remastering serial test ISO (${#maps[@]} map args)"
  xorriso -indev "$ISO" -outdev "$OUT/serial.iso" -boot_image any replay \
    "${maps[@]}" -commit >"$OUT/remaster.log" 2>&1
  grep -h 'boot=live' "$work"/boot/grub/*.cfg "$work"/isolinux/*.cfg 2>/dev/null | head -n 5 > "$OUT/test-cmdline.txt" || true
  rm -rf "$work"
  ISO="$OUT/serial.iso"
fi

SERIAL="$OUT/serial.log"; : > "$SERIAL"
shot_times=(8 15 25 40 60 90 120 150 180 240 300 360 420 480 540 600)

ocr() { # $1 = png -> prints text
  local tmp="$OUT/.ocr.png"
  convert "$1" -resize 200% -colorspace Gray -normalize "$tmp" 2>/dev/null || cp "$1" "$tmp"
  local a b
  a="$(tesseract "$tmp" - 2>/dev/null || true)"
  convert "$tmp" -negate "$tmp.neg.png" 2>/dev/null && b="$(tesseract "$tmp.neg.png" - 2>/dev/null || true)" || b=""
  printf '%s\n%s\n' "$a" "$b" | tr -s ' \n' | sed '/^\s*$/d'
  rm -f "$tmp" "$tmp.neg.png"
}

# --------------------------------------------------------------------------
start_qemu() {
  local accel=(-accel tcg)
  [[ -w /dev/kvm ]] && accel=(-enable-kvm -cpu host)
  local fw=() machine="q35"
  case "$FW" in
    uefi)
      cp /usr/share/OVMF/OVMF_VARS_4M.fd "$OUT/vars.fd"
      fw=(-drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
          -drive if=pflash,format=raw,unit=1,file="$OUT/vars.fd") ;;
    uefi-sb)
      cp /usr/share/OVMF/OVMF_VARS_4M.ms.fd "$OUT/vars.fd"
      machine="q35,smm=on"
      fw=(-global driver=cfi.pflash01,property=secure,value=on
          -drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd
          -drive if=pflash,format=raw,unit=1,file="$OUT/vars.fd") ;;
    bios) ;;
    *) echo "unknown FW $FW"; exit 2 ;;
  esac
  local media=()
  case "$MEDIA" in
    cdrom) media=(-drive file="$ISO",media=cdrom,readonly=on,if=none,id=cd0 -device ide-cd,drive=cd0,bootindex=0) ;;
    usb)   media=(-device qemu-xhci -drive file="$ISO",format=raw,readonly=on,if=none,id=usb0 -device usb-storage,drive=usb0,bootindex=0) ;;
  esac
  log "starting QEMU fw=$FW media=$MEDIA accel=${accel[*]}"
  qemu-system-x86_64 -machine "$machine" "${accel[@]}" -m 4096 -smp 2 \
    "${fw[@]}" "${media[@]}" \
    -vga std -display none -serial file:"$SERIAL" \
    -monitor unix:"$OUT/mon.sock",server,nowait \
    -nic user,model=virtio-net-pci -device virtio-rng-pci \
    >"$OUT/qemu.log" 2>&1 &
  VM_PID=$!
}
shot_qemu() { # $1 = png path
  echo "screendump $OUT/.shot.ppm" | socat - UNIX-CONNECT:"$OUT/mon.sock" >/dev/null 2>&1 || return 1
  sleep 1; convert "$OUT/.shot.ppm" "$1" 2>/dev/null; rm -f "$OUT/.shot.ppm"
}
alive_qemu() { kill -0 "$VM_PID" 2>/dev/null; }
stop_qemu() { echo quit | socat - UNIX-CONNECT:"$OUT/mon.sock" >/dev/null 2>&1 || kill "$VM_PID" 2>/dev/null || true; }

VM="t44os-$NAME"
start_vbox() {
  [[ "$FW" == bios ]] && fwopt=bios || fwopt=efi
  VBoxManage createvm --name "$VM" --ostype Debian_64 --register >/dev/null
  VBoxManage modifyvm "$VM" --firmware "$fwopt" --memory 4096 --cpus 2 \
    --graphicscontroller vmsvga --vram 64 --audio-driver none --usb off \
    --uart1 0x3F8 4 --uartmode1 file "$SERIAL" --boot1 dvd --boot2 disk
  VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci
  VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type dvddrive --medium "$ISO"
  log "starting VirtualBox $(VBoxManage --version) fw=$fwopt"
  VBoxManage startvm "$VM" --type headless >"$OUT/vbox.log" 2>&1
}
shot_vbox() { VBoxManage controlvm "$VM" screenshotpng "$1" >/dev/null 2>&1; }
alive_vbox() { VBoxManage showvminfo "$VM" --machinereadable 2>/dev/null | grep -q '^VMState="running"'; }
stop_vbox() {
  VBoxManage controlvm "$VM" poweroff >/dev/null 2>&1 || true; sleep 3
  cp -f "$HOME/VirtualBox VMs/$VM/Logs/VBox.log" "$OUT/VBox-internal.log" 2>/dev/null || true
  VBoxManage unregistervm "$VM" --delete >/dev/null 2>&1 || true
}

# --------------------------------------------------------------------------
"start_$HV"
t0=$(date +%s); idx=0
stage_grub=0; stage_kernel=0; stage_graphical=0
: > "$OUT/ocr.txt"
check_stages() {
  if grep -qiE 'GNU GRUB|Live system|44OS Live|Start 44OS' "$OUT/ocr.txt" "$SERIAL" 2>/dev/null; then stage_grub=1; fi
  if grep -qaE 'Welcome to|Reached target|login:|Run /init|Freeing unused kernel' "$SERIAL"; then stage_kernel=1; stage_grub=1; fi
  if grep -qaE 'Reached target graphical\.target|Graphical Interface' "$SERIAL"; then stage_graphical=1; fi
}
for t in "${shot_times[@]}"; do
  (( t > DURATION )) && break
  now=$(( $(date +%s) - t0 )); (( t > now )) && sleep $(( t - now ))
  "alive_$HV" || { log "VM exited early"; break; }
  idx=$((idx+1)); png="$OUT/shot-$(printf %02d $idx)-${t}s.png"
  if "shot_$HV" "$png"; then
    { echo "--- t=${t}s"; ocr "$png"; } >> "$OUT/ocr.txt"
  fi
  check_stages
  case "$REQUIRE" in
    grub)      (( stage_grub )) && (( t >= 25 )) && break ;;
    kernel)    (( stage_kernel )) && break ;;
    graphical) (( stage_graphical )) && (( t >= 120 )) && break ;;
  esac
done
# One last screenshot so the final state is always captured.
"alive_$HV" && "shot_$HV" "$OUT/final.png" && { echo "--- final"; ocr "$OUT/final.png"; } >> "$OUT/ocr.txt" || true
check_stages
"stop_$HV"
sleep 2

{
  echo "name=$NAME hv=$HV fw=$FW media=$MEDIA serial_iso=$SERIAL_ISO elapsed=$(( $(date +%s) - t0 ))s"
  echo "stage_grub=$stage_grub stage_kernel=$stage_kernel stage_graphical=$stage_graphical"
  echo "--- serial (key lines)"
  grep -aE 'GRUB|Linux version|Welcome to|Reached target|Failed|login:|sddm|error|panic' "$SERIAL" | tail -n 40 || true
  echo "--- OCR"
  tail -n 80 "$OUT/ocr.txt"
} > "$OUT/result.txt"
cat "$OUT/result.txt"

case "$REQUIRE" in
  grub)      (( stage_grub )) ;;
  kernel)    (( stage_kernel )) ;;
  graphical) (( stage_graphical )) ;;
  none)      true ;;
esac
