#!/usr/bin/env bash
# Publish test results (text + JPEG screenshots) to a ci-results/<run>-<name>
# branch so they can be inspected without downloading artifacts.
# Usage: publish-results.sh SRC_DIR NAME   (needs GH_TOKEN, GITHUB_REPOSITORY, GITHUB_RUN_ID)
set -Eeuo pipefail
src="$1"; name="$2"; pub="$(mktemp -d)"
[[ -d "$src" ]] || exit 0
(cd "$src" && find . -maxdepth 2 \( -name '*.txt' -o -name '*.log' \) ! -name '.*' -size -2M -print0 \
   | xargs -0 -r cp --parents -t "$pub")
while IFS= read -r -d '' p; do
  rel="${p#"$src"/}"; mkdir -p "$pub/$(dirname "$rel")"
  convert "$p" -quality 82 "$pub/${rel%.png}.jpg"
done < <(find "$src" -maxdepth 2 -name '*.png' ! -name '.*' ! -name 'click.png' ! -name 'wait.png' -print0)
cd "$pub"
git init -q -b results
git config user.name "44os-ci"; git config user.email "44os-ci@users.noreply.github.com"
git add -A && git commit -qm "Test results: $name (run $GITHUB_RUN_ID)"
git push -q -f "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}" \
  "results:refs/heads/ci-results/${GITHUB_RUN_ID}-${name}"
