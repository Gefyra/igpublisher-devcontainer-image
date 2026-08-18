#!/usr/bin/env bash
# devcontainer postStartCommand - runs on every container start, so keep it fast
# and never fail the start. Reports which IG Publisher you are about to build
# with, because stopping and starting a container - or a Codespace - never
# updates it: postCreateCommand does not run again.
set -uo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

STALE_DAYS=14

is_ig_workspace || exit 0

if [ ! -e "$CACHE_JAR" ]; then
  echo "IG Publisher: no jar at $CACHE_JAR - run the 'Update IG Publisher' task."
  exit 0
fi

version=$(jar_version "$CACHE_JAR")
[ -n "$version" ] || version="unknown"

# -L dereferences, so a linked jar reports the image's build date rather than
# the mtime of the link itself. Neither GNU nor BSD stat follows links by default.
mtime=$(stat -Lc %Y "$CACHE_JAR" 2>/dev/null || stat -Lf %m "$CACHE_JAR" 2>/dev/null || echo 0)
if [ "$mtime" -gt 0 ]; then
  age=$(( ( $(date +%s) - mtime ) / 86400 ))
  built=$(date -d "@$mtime" +%Y-%m-%d 2>/dev/null || date -r "$mtime" +%Y-%m-%d 2>/dev/null)
else
  age=-1
  built="unknown"
fi

if [ -L "$CACHE_JAR" ]; then
  origin="from the image"
  remedy="'Codespaces: Full Rebuild Container' or 'Dev Containers: Rebuild Container' pulls a new image."
else
  origin="fetched manually"
  remedy="Run the 'Update IG Publisher' task."
fi

echo "IG Publisher $version ($origin, $built)"
if [ "$age" -ge "$STALE_DAYS" ]; then
  echo "  ⚠ $age days old. $remedy"
fi
