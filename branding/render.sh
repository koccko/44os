#!/usr/bin/env bash
# Regenerate the raster 44OS branding assets from branding/src.
# Requirements: rsvg-convert (librsvg2-bin), ImageMagick, fonts-inter, python3.
# The generated files are committed so the ISO build needs none of these tools.
set -Eeuo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/src" && pwd)"
BR="$(cd "$SRC/.." && pwd)"
ROOT="$(cd "$BR/.." && pwd)/config/includes.chroot"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP" "$SRC/wallpaper-1920.png"' EXIT

ICONS="$ROOT/usr/share/icons/hicolor"
BRAND="$ROOT/usr/share/44os/branding"
CALA="$ROOT/etc/calamares/branding/44os"
PLY="$ROOT/usr/share/plymouth/themes/44nova"
LNF="$ROOT/usr/share/plasma/look-and-feel/org.44os.desktop/contents"
mkdir -p "$ICONS/scalable/apps" "$BRAND" "$CALA" "$PLY" "$ROOT/usr/share/pixmaps" \
         "$ROOT/usr/share/44os/faces" "$ROOT/etc/skel" "$LNF/previews" "$LNF/splash/images"

# Vector icons
install -m644 "$SRC/44os-icon.svg"     "$ICONS/scalable/apps/44os-logo.svg"
install -m644 "$SRC/44os-symbolic.svg" "$ICONS/scalable/apps/44os-start.svg"
install -m644 "$SRC/44os-launcher.svg" "$ICONS/scalable/apps/44os-launcher.svg"
install -m644 "$SRC/44os-icon.svg"     "$ROOT/usr/share/pixmaps/44os-logo.svg"
install -m644 "$SRC/44os-mark.svg"     "$BRAND/44os-mark.svg"

# Raster icons for consumers that do not render SVG well
for s in 32 48 64 128 256; do
  mkdir -p "$ICONS/${s}x${s}/apps"
  rsvg-convert -w "$s" -h "$s" "$SRC/44os-icon.svg" -o "$ICONS/${s}x${s}/apps/44os-logo.png"
  rsvg-convert -w "$s" -h "$s" "$SRC/44os-launcher.svg" -o "$ICONS/${s}x${s}/apps/44os-launcher.png"
done
rsvg-convert -w 256 -h 256 "$SRC/44os-icon.svg" -o "$ROOT/usr/share/pixmaps/44os-logo.png"
rsvg-convert -w 620 "$SRC/44os-wordmark.svg" -o "$BRAND/44os-wordmark.png"
rsvg-convert -w 620 "$SRC/44os-nova-wordmark.svg" -o "$BRAND/44os-nova-wordmark.png"
install -m644 "$SRC/44os-nova-wordmark.svg" "$BRAND/44os-nova-wordmark.svg"
rsvg-convert -w 256 "$SRC/44os-mark.svg" -o "$BRAND/44os-mark.png"

# Default avatar (SDDM fallback face, new users' ~/.face)
rsvg-convert -w 256 -h 256 "$SRC/avatar.svg" -o "$ROOT/usr/share/44os/faces/.face.icon"
cp "$ROOT/usr/share/44os/faces/.face.icon" "$ROOT/etc/skel/.face"
cp "$ROOT/usr/share/44os/faces/.face.icon" "$BRAND/avatar.png"

# Wallpaper packages (light grain added to avoid gradient banding)
wallpaper() { # $1 = svg, $2 = package dir
  local dir="$ROOT/usr/share/wallpapers/$2/contents"
  mkdir -p "$dir/images"
  rsvg-convert "$SRC/$1" -o "$TMP/wall.png"
  convert "$TMP/wall.png" -attenuate 0.35 +noise Gaussian -quality 90 "$dir/images/3840x2160.jpg"
  convert "$dir/images/3840x2160.jpg" -resize 2560x1440 -quality 90 "$dir/images/2560x1440.jpg"
  convert "$dir/images/3840x2160.jpg" -resize 1920x1080 -quality 90 "$dir/images/1920x1080.jpg"
  convert "$dir/images/3840x2160.jpg" -resize 400x225 -quality 85 "$dir/screenshot.jpg"
}
wallpaper wallpaper-nova.svg 44OS-Nova
wallpaper wallpaper-horizon.svg 44OS
NOVA="$ROOT/usr/share/wallpapers/44OS-Nova/contents/images"
cp "$ROOT/usr/share/wallpapers/44OS-Nova/contents/screenshot.jpg" "$LNF/previews/preview.jpg"
convert "$NOVA/1920x1080.jpg" -resize 1280x720 -quality 85 "$LNF/previews/fullscreenpreview.jpg"

# 44Welcome hero image: Nova crop with a left-side scrim, rounded corners
convert "$NOVA/2560x1440.jpg" -crop 2400x960+160+300 +repage -resize 1400x560! \
  \( -size 560x1400 gradient:'rgba(8,13,24,0.94)'-'rgba(8,13,24,0.05)' -rotate -90 \) \
  -compose over -composite "$TMP/hero.png"
convert -size 1400x560 xc:none -fill white -draw "roundrectangle 0,0 1399,559 28,28" "$TMP/mask.png"
convert "$TMP/hero.png" "$TMP/mask.png" -alpha off -compose CopyOpacity -composite "$BRAND/welcome-hero.png"

# Plasma startup splash images
rsvg-convert -w 256 "$SRC/44os-mark.svg" -o "$LNF/splash/images/44os-mark.png"
rsvg-convert -w 620 "$SRC/44os-nova-wordmark.svg" -o "$LNF/splash/images/44os-nova-wordmark.png"

# Plymouth boot splash (two-step theme)
python3 "$BR/plymouth.py" "$TMP/ply"
for f in "$TMP"/ply/*.svg; do
  n="$(basename "${f%.svg}")"
  rsvg-convert "$f" -o "$PLY/$n.png"
done
rsvg-convert -w 300 "$SRC/44os-nova-wordmark.svg" -o "$PLY/watermark.png"

# Calamares branding images
convert "$NOVA/1920x1080.jpg" "$SRC/wallpaper-1920.png"
rsvg-convert -w 256 -h 256 "$SRC/44os-icon.svg" -o "$CALA/44os-logo.png"
(cd "$SRC" && rsvg-convert calamares-welcome.svg -o "$CALA/welcome.png")
(cd "$SRC" && rsvg-convert calamares-slide.svg -o "$CALA/slide1.png")

python3 "$BR/colors.py"
echo "branding assets rendered into $ROOT"
