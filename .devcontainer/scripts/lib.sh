#!/usr/bin/env bash
# Shared helpers for the lifecycle scripts and task wrappers. Source, don't execute.
#
# Everything here assumes the caller runs in the workspace folder, which is what
# devcontainer lifecycle commands and VS Code shell tasks both do.

IMAGE_JAR=/opt/ig/publisher.jar
CACHE_JAR=input-cache/publisher.jar

# Prints the IG Publisher version of the jar at $1, empty if it can't be read.
# Avoids starting the JVM: the manifest's Class-Path names
# org.hl7.fhir.publisher.core-<version>.jar. Manifest lines wrap at 72 chars
# with a leading space on continuations, so unfold before matching.
#
# Must never return non-zero: callers run under `set -e` with pipefail, where an
# unreadable jar would otherwise make grep exit 1 and abort the whole script.
jar_version() {
  unzip -p "$1" META-INF/MANIFEST.MF 2>/dev/null \
    | tr -d '\r' \
    | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n //g' \
    | grep -o 'org\.hl7\.fhir\.publisher\.core-[0-9][0-9.]*\.jar' \
    | head -1 | sed 's/.*core-\(.*\)\.jar/\1/' || true
}

# True if version $1 >= version $2. Compares component-wise and numerically,
# so 2.2.10 correctly beats 2.2.9. Uses awk rather than `sort -V` to stay
# portable - BSD sort has no -V, which matters when testing outside the image.
version_ge() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    na = split(a, x, "."); nb = split(b, y, ".")
    n = (na > nb ? na : nb)
    for (i = 1; i <= n; i++) {
      ai = (i <= na ? x[i] + 0 : 0)
      bi = (i <= nb ? y[i] + 0 : 0)
      if (ai > bi) exit 0
      if (ai < bi) exit 1
    }
    exit 0
  }'
}

# Size of $1 in whole MB, dereferencing symlinks.
jar_mb() {
  local bytes
  bytes=$(stat -Lc %s "$1" 2>/dev/null || stat -Lf %z "$1" 2>/dev/null || echo 0)
  echo $(( bytes / 1024 / 1024 ))
}

# True if the current directory looks like an IG project. Used to stay quiet in
# workspaces that merely happen to use this image.
is_ig_workspace() {
  [ -f ig.ini ] || [ -f _updatePublisher.sh ] || [ -e "$CACHE_JAR" ]
}
