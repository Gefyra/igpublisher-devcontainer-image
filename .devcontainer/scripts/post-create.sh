#!/usr/bin/env bash
# devcontainer postCreateCommand - runs once per container, including rebuilds.
# Declared by the image itself via the devcontainer.metadata label, so every
# project using this image gets it without carrying a copy.
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

is_ig_workspace || exit 0

# The IG Publisher scripts expect the jar in ./input-cache/, the image ships one
# at /opt/ig/publisher.jar. Symlink instead of copying so the ~220 MB jar exists
# exactly once. _genonce.sh only reads it, which works fine through the link.
#
# The link is NOT writable (root-owned /opt), so `ig-update-publisher` removes it
# first and downloads a real file in its place.
mkdir -p input-cache

# The workspace outlives the container, so a link from an earlier one may still
# be here pointing at nothing. Drop it before deciding what to do.
if [ -L "$CACHE_JAR" ] && [ ! -e "$CACHE_JAR" ]; then
  rm -f "$CACHE_JAR"
fi

if [ ! -e "$CACHE_JAR" ]; then
  if [ -f "$IMAGE_JAR" ]; then
    echo "Linking $CACHE_JAR -> $IMAGE_JAR"
    ln -s "$IMAGE_JAR" "$CACHE_JAR"
  elif [ -f _updatePublisher.sh ]; then
    bash _updatePublisher.sh -y
  else
    echo "No publisher in the image and no _updatePublisher.sh - skipped."
  fi

elif [ ! -L "$CACHE_JAR" ] && [ -f "$IMAGE_JAR" ]; then
  # A real file left over from `ig-update-publisher`. Once the image has caught
  # up, that copy buys nothing and just costs another ~220 MB, so fall back to
  # the link. Only ever replaces it with an equal or newer publisher; if either
  # version can't be read we keep the copy, because guessing could downgrade it.
  cached=$(jar_version "$CACHE_JAR")
  image=$(jar_version "$IMAGE_JAR")

  if [ -n "$cached" ] && [ -n "$image" ] && version_ge "$image" "$cached"; then
    freed=$(jar_mb "$CACHE_JAR")
    rm -f "$CACHE_JAR"
    ln -s "$IMAGE_JAR" "$CACHE_JAR"
    echo "Image publisher $image >= local copy $cached - relinked, freed ~${freed} MB."
  fi
fi

# Projects created from the template before the tasks moved into the image still
# call _updatePublisher.sh directly. That writes with `curl -o`, which follows
# the link we just created into root-owned /opt and fails with curl exit 23.
# Nothing is destroyed, but the task is broken until tasks.json is updated.
if [ -L "$CACHE_JAR" ] && [ -f .vscode/tasks.json ] \
   && grep -q '_updatePublisher\.sh' .vscode/tasks.json 2>/dev/null; then
  echo ""
  echo "⚠ .vscode/tasks.json calls _updatePublisher.sh directly."
  echo "  The 'Update IG Publisher' task fails that way: curl cannot write"
  echo "  through the symlink into /opt. Replace its command with:"
  echo "      ig-update-publisher"
  echo ""
fi

echo "Devcontainer ready."
