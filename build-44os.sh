#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "$(id -u)" -ne 0 ]]; then echo 'Run as root: sudo bash build-44os.sh' >&2; exit 1; fi
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
mkdir -p work dist
cp -a config/. work/config/
cd work
lb config --mode debian --distribution trixie --architecture amd64 \
  --binary-images iso-hybrid --archive-areas 'main contrib non-free non-free-firmware' \
  --iso-volume '44OS_ALPHA' \
  --debian-installer none --apt-recommends true
lb build
ISO="$(find . -maxdepth 1 -type f -name '*.iso' -print -quit)"
if [[ -z "$ISO" ]]; then echo 'No ISO produced' >&2; exit 1; fi
cp "$ISO" "$ROOT/dist/44OS-0.1-alpha-live-amd64.iso"
