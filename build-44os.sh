
#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$ROOT/work"
DIST="$ROOT/dist"

if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: Run as root"
  exit 1
fi

echo "=================================="
echo "       44OS 0.1 ALPHA BUILD"
echo "=================================="

rm -rf "$WORK"
mkdir -p "$WORK" "$DIST"
cd "$WORK"

lb config \
  --mode debian \
  --distribution trixie \
  --architecture amd64 \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --mirror-bootstrap "https://deb.debian.org/debian/" \
  --mirror-chroot "https://deb.debian.org/debian/" \
  --mirror-binary "https://deb.debian.org/debian/" \
  --security true \
  --mirror-chroot-security "https://security.debian.org/debian-security/" \
  --mirror-binary-security "https://security.debian.org/debian-security/" \
  --iso-volume "44OS_ALPHA" \
  --debian-installer none \
  --apt-recommends true

# Copy our custom package lists and configuration
cp -a "$ROOT/config/." "$WORK/config/"

echo "=== 44OS BUILD CONFIG ==="
grep -E 'LB_(DISTRIBUTION|SECURITY|MIRROR_CHROOT_SECURITY|MIRROR_BINARY_SECURITY)=' \
  config/* 2>/dev/null || true

echo "=== BUILDING 44OS ==="
lb build

ISO="$(find "$WORK" -maxdepth 1 -type f -name '*.iso' -print -quit)"

if [[ -z "$ISO" ]]; then
  echo "ERROR: ISO file was not generated"
  exit 1
fi

cp "$ISO" "$DIST/44OS-0.1-alpha-live-amd64.iso"

echo "=================================="
echo "  44OS ISO BUILD COMPLETED"
echo "=================================="
ls -lh "$DIST"
