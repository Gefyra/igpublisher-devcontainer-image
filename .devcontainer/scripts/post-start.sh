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
  echo "IG Publisher: kein Jar in $CACHE_JAR - Task 'Update IG Publisher' ausführen."
  exit 0
fi

version=$(jar_version "$CACHE_JAR")
[ -n "$version" ] || version="unbekannt"

# -L dereferences, so a linked jar reports the image's build date rather than
# the mtime of the link itself. Neither GNU nor BSD stat follows links by default.
mtime=$(stat -Lc %Y "$CACHE_JAR" 2>/dev/null || stat -Lf %m "$CACHE_JAR" 2>/dev/null || echo 0)
if [ "$mtime" -gt 0 ]; then
  age=$(( ( $(date +%s) - mtime ) / 86400 ))
  built=$(date -d "@$mtime" +%d.%m.%Y 2>/dev/null || date -r "$mtime" +%d.%m.%Y 2>/dev/null)
else
  age=-1
  built="unbekannt"
fi

if [ -L "$CACHE_JAR" ]; then
  origin="aus dem Image"
  remedy="'Codespaces: Full Rebuild Container' bzw. 'Dev Containers: Rebuild Container' holt ein neues Image."
else
  origin="manuell geladen"
  remedy="Task 'Update IG Publisher' ausführen."
fi

echo "IG Publisher $version ($origin, $built)"
if [ "$age" -ge "$STALE_DAYS" ]; then
  echo "  ⚠ $age Tage alt. $remedy"
fi
