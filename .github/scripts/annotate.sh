#!/usr/bin/env bash
# Publish a text file as a GitHub Actions annotation so results are visible
# in the run summary (and through the check-runs API) without downloading logs.
# Usage: annotate.sh <notice|warning|error> <title> <file> [max-bytes]
set -u
level="$1"; title="$2"; file="$3"; max="${4:-30000}"
[ -f "$file" ] || { echo "::${level} title=${title}::(missing: ${file})"; exit 0; }
body="$(head -c "$max" "$file" | tr -d '\r' | sed -e 's/%/%25/g' | awk 'BEGIN{ORS="%0A"} {print}')"
echo "::${level} title=${title}::${body}"
