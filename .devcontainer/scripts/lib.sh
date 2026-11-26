#!/usr/bin/env bash
# Shared helpers for the lifecycle scripts and task wrappers. Source, don't execute.
#
# Everything here assumes the caller runs in the workspace folder, which is what
# devcontainer lifecycle commands and VS Code shell tasks both do.

IMAGE_JAR=/opt/ig/publisher.jar
CACHE_JAR=input-cache/publisher.jar
# The HL7 build scripts look for the jar in input-cache/ first, then in the
# parent folder. The image's jar is linked in as the parent's: IG Publisher 3.x
# refuses to build an IG whose folder holds a symbolic link that leads out of
# it, and the parent folder is outside the IG's.
PARENT_JAR=../publisher.jar

# Runs "$@", retrying with sudo when the current user may not write there
# (in Codespaces, /workspaces can belong to root).
as_needed() {
  "$@" 2>/dev/null || sudo -n "$@"
}

# Points ../publisher.jar at the image's jar. Leaves a real file there alone:
# that one was put there on purpose.
link_parent_jar() {
  [ -f "$IMAGE_JAR" ] || return 0
  if [ -e "$PARENT_JAR" ] && [ ! -L "$PARENT_JAR" ]; then
    return 0
  fi
  as_needed ln -sfn "$IMAGE_JAR" "$PARENT_JAR"
}

# The jar the build scripts will run, in their order of preference. Empty if none.
effective_jar() {
  if [ -f "$CACHE_JAR" ]; then
    echo "$CACHE_JAR"
  elif [ -f "$PARENT_JAR" ]; then
    echo "$PARENT_JAR"
  fi
}

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

# Adds "  <label>: <page>" to the menu in sushi-config.yaml, after its last
# entry. Prints what happened. Returns non-zero if there is no menu: block to
# add to (the IG may manage input/includes/menu.xml itself).
add_menu_entry() {
  python3 -I - "$1" "$2" <<'PY'
import re, sys
label, page = sys.argv[1], sys.argv[2]
path = "sushi-config.yaml"
try:
    with open(path, encoding="utf-8", newline="") as f:
        text = f.read()
except FileNotFoundError:
    print(f"  No {path} - add '{label}: {page}' to the IG's menu yourself.")
    sys.exit(1)
nl = "\r\n" if "\r\n" in text else "\n"
lines = text.split(nl)
start = next((i for i, l in enumerate(lines) if re.match(r"^menu:\s*(#.*)?$", l)), None)
if start is None:
    print(f"  No menu: in {path} - add '{label}: {page}' to the IG's menu yourself.")
    sys.exit(1)
# Entries go at the top level of the menu, indented like its first entry.
last, indent = start, None
for i in range(start + 1, len(lines)):
    l = lines[i]
    if not l.strip() or l.lstrip().startswith("#"):
        continue
    if not l[0].isspace():
        break
    if re.search(r":\s*" + re.escape(page) + r"\s*(#.*)?$", l):
        print(f"  The menu already links {page}.")
        sys.exit(0)
    last = i
    if indent is None:
        indent = re.match(r"^(\s*)", l).group(1)
lines.insert(last + 1, f"{indent or '  '}{label}: {page}")
with open(path, "w", encoding="utf-8", newline="") as f:
    f.write(nl.join(lines))
print(f"  Added '{label}: {page}' to the menu in {path}.")
PY
}

# Copies a page from the image into input/pagecontent/ unless it is there.
# $1 = file name, $2 = menu label. Returns non-zero if it already existed.
add_page() {
  local name=$1 label=$2 dest=input/pagecontent/$1
  if [ -e "$dest" ]; then
    echo "ℹ $dest already exists - left alone."
    return 1
  fi
  mkdir -p input/pagecontent
  cp "/usr/local/share/ig-devcontainer/pages/$name" "$dest" || return 1
  echo "✓ Added $dest"
  add_menu_entry "$label" "${name%.md}.html" || true
  if grep -qE '^pages:' sushi-config.yaml 2>/dev/null; then
    echo "  ⚠ sushi-config.yaml lists its pages itself (pages:) - add $name there too."
  fi
}
