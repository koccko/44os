#!/usr/bin/env bash
# Publish a downscaled screenshot as base64 chunks in GitHub annotations so it
# can be inspected without downloading artifacts.
# Usage: annotate-image.sh <title> <png> [width]
set -u
title="$1"; png="$2"; width="${3:-1024}"
[ -f "$png" ] || exit 0
tmp="$(mktemp --suffix=.jpg)"
convert "$png" -resize "${width}x" -quality 55 "$tmp" 2>/dev/null || exit 0
data="$(base64 -w0 "$tmp")"; rm -f "$tmp"
n=$(( (${#data} + 29999) / 30000 ))
for ((i=0; i<n; i++)); do
  echo "::notice title=IMG ${title} $((i+1))/${n}::${data:$((i*30000)):30000}"
done
