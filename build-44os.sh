
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT/work" "$ROOT/dist"

cd "$ROOT/work"
lb clean --purge || true

lb config \
  --mode debian \
  --distribution trixie \
  --architecture amd64 \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap "https://deb.debian.org/debian/" \
  --mirror-chroot "https://deb.debian.org/debian/" \
  --mirror-binary "https://deb.debian.org/debian/" \
  --security false \
  --iso-volume "44OS_ALPHA" \
  --debian-installer none \
  --apt-recommends true

cp -a "$ROOT/config/." config/

lb build

ISO="$(find . -maxdepth 1 -type f -name '*.iso' -print -quit)"

if [[ -z "$ISO" ]]; then
  echo "ERROR: ISO was not generated" >&2
  exit 1
fi

cp "$ISO" "$ROOT/dist/44OS-0.1-alpha-live-amd64.iso"
