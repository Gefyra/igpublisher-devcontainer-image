#!/usr/bin/env bash
# devcontainer postCreateCommand - runs once per container, including rebuilds.
# Declared by the image itself via the devcontainer.metadata label, so every
# project using this image gets it without carrying a copy.
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

is_ig_workspace || exit 0

mkdir -p input-cache

# Earlier versions of this image linked input-cache/publisher.jar to the image's
# jar. IG Publisher 3.x stops on any symbolic link that leads out of the IG's
# folder, so that link has to go - including one left behind in a workspace
# that outlived its container.
if [ -L "$CACHE_JAR" ]; then
  rm -f "$CACHE_JAR"
  echo "Removed the old link $CACHE_JAR (IG Publisher 3.x refuses links out of the IG)."
fi

if [ -f "$IMAGE_JAR" ]; then
  # The build scripts fall back to ../publisher.jar when input-cache/ has none.
  # Linking the image's jar there keeps the ~220 MB jar in one place, outside
  # the IG's folder where the publisher doesn't object.
  if link_parent_jar; then
    echo "Linked $PARENT_JAR -> $IMAGE_JAR"
  else
    echo "⚠ Could not link $PARENT_JAR - run the 'Update IG Publisher' task before building."
  fi

  if [ -f "$CACHE_JAR" ]; then
    # A real file left over from `ig-update-publisher`. It takes precedence over
    # the parent's jar. Once the image has caught up, that copy buys nothing and
    # just costs another ~220 MB, so remove it. Only when the image's publisher
    # is equal or newer; if either version can't be read we keep the copy,
    # because guessing could downgrade it.
    cached=$(jar_version "$CACHE_JAR")
    image=$(jar_version "$IMAGE_JAR")

    if [ -n "$cached" ] && [ -n "$image" ] && version_ge "$image" "$cached"; then
      freed=$(jar_mb "$CACHE_JAR")
      rm -f "$CACHE_JAR"
      echo "Image publisher $image >= local copy $cached - removed the copy, freed ~${freed} MB."
    fi
  fi
elif [ ! -f "$CACHE_JAR" ] && [ -f _updatePublisher.sh ]; then
  bash _updatePublisher.sh -y
elif [ ! -f "$CACHE_JAR" ]; then
  echo "No publisher in the image and no _updatePublisher.sh - skipped."
fi

echo "Devcontainer ready."
