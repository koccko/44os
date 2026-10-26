#!/usr/bin/env bash
# Verify every package in config/package-lists exists in the configured
# Debian archive (run inside a Debian trixie environment after apt-get update).
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
missing=0
for list in config/package-lists/*.list.chroot; do
  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      printf '  ok  %s\n' "$pkg"
    else
      printf 'MISSING %s (%s)\n' "$pkg" "$list"; missing=1
    fi
  done < <(sed 's/#.*//' "$list" | tr -s ' \t' '\n')
done
exit "$missing"
