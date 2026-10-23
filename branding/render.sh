#!/usr/bin/env bash
# Regenerate the raster 44OS branding assets from branding/src.
# Requirements: rsvg-convert (librsvg2-bin), ImageMagick, fonts-inter.
# The generated files are committed so the ISO build needs none of these tools.
set -Eeuo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/src" && pwd)"
ROOT="$(cd "$SRC/../.." && pwd)/config/includes.chroot"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

ICONS="$ROOT/usr/share/icons/hicolor"
WALL="$ROOT/usr/share/wallpapers/44OS/contents"
BRAND="$ROOT/usr/share/44os/branding"
CALA="$ROOT/etc/calamares/branding/44os"
mkdir -p "$ICONS/scalable/apps" "$WALL/images" "$BRAND" "$CALA" "$ROOT/usr/share/pixmaps"

# Vector icons
install -m644 "$SRC/44os-icon.svg"     "$ICONS/scalable/apps/44os-logo.svg"
install -m644 "$SRC/44os-symbolic.svg" "$ICONS/scalable/apps/44os-start.svg"
install -m644 "$SRC/44os-icon.svg"     "$ROOT/usr/share/pixmaps/44os-logo.svg"
install -m644 "$SRC/44os-mark.svg"     "$BRAND/44os-mark.svg"

# Raster icons for consumers that do not render SVG well
for s in 32 48 64 128 256; do
  mkdir -p "$ICONS/${s}x${s}/apps"
  rsvg-convert -w "$s" -h "$s" "$SRC/44os-icon.svg" -o "$ICONS/${s}x${s}/apps/44os-logo.png"
done
rsvg-convert -w 256 -h 256 "$SRC/44os-icon.svg" -o "$ROOT/usr/share/pixmaps/44os-logo.png"
rsvg-convert -w 620 "$SRC/44os-wordmark.svg" -o "$BRAND/44os-wordmark.png"
rsvg-convert -w 256 "$SRC/44os-mark.svg" -o "$BRAND/44os-mark.png"

# Wallpaper package (light grain added to avoid gradient banding)
rsvg-convert "$SRC/wallpaper.svg" -o "$TMP/wall.png"
convert "$TMP/wall.png" -attenuate 0.35 +noise Gaussian -quality 90 "$WALL/images/3840x2160.jpg"
convert "$WALL/images/3840x2160.jpg" -resize 2560x1440 -quality 90 "$WALL/images/2560x1440.jpg"
convert "$WALL/images/3840x2160.jpg" -resize 1920x1080 -quality 90 "$WALL/images/1920x1080.jpg"
convert "$WALL/images/3840x2160.jpg" -resize 400x225 -quality 85 "$WALL/screenshot.jpg"

# Calamares branding images
convert "$WALL/images/1920x1080.jpg" "$SRC/wallpaper-1920.png"
trap 'rm -rf "$TMP" "$SRC/wallpaper-1920.png"' EXIT
rsvg-convert -w 256 -h 256 "$SRC/44os-icon.svg" -o "$CALA/44os-logo.png"
(cd "$SRC" && rsvg-convert calamares-welcome.svg -o "$CALA/welcome.png")
(cd "$SRC" && rsvg-convert calamares-slide.svg -o "$CALA/slide1.png")
python3 "$SRC/../colors.py"
echo "branding assets rendered into $ROOT"
