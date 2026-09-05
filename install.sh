#!/usr/bin/env bash
# Usage: bash install.sh /path/to/MyVault [--skip-git]
# Copies only scaffold-files.txt entries. Existing files and Git history stay untouched.
set -euo pipefail

DEST="${1:-}"
SKIP_GIT="${2:-}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [ -z "$DEST" ] || [ "$#" -gt 2 ] || { [ -n "$SKIP_GIT" ] && [ "$SKIP_GIT" != "--skip-git" ]; }; then
  echo "Usage: bash install.sh /path/to/MyVault [--skip-git]" >&2
  exit 1
fi
fail() { echo "Install stopped: $*" >&2; exit 1; }

# Resolve existing directory links and lexical .. without creating the destination.
canonical_dir() {
  local raw="$1" current="/" part
  local parts=()
  case "$raw" in *$'\n'*|*$'\r'*) fail "Directory paths cannot contain newlines." ;; esac
  case "$raw" in /*) ;; *) raw="$PWD/$raw" ;; esac
  IFS='/' read -r -a parts <<< "$raw"
  for part in "${parts[@]}"; do
    case "$part" in
      ''|.) continue ;;
      ..) current="$(dirname "$current")" ;;
      *) current="${current%/}/$part"
         if [ -d "$current" ]; then current="$(cd "$current" && pwd -P)"
         elif [ -e "$current" ] || [ -L "$current" ]; then fail "Not a directory: $current"; fi ;;
    esac
  done
  printf '%s\n' "$current"
}
DEST="$(canonical_dir "$DEST")"
case "$DEST/" in "$SRC/"*) fail "Source and destination must not overlap." ;; esac
case "$SRC/" in "$DEST/"*) fail "Source and destination must not overlap." ;; esac

# Check every source and destination before copying anything. Reject existing links,
# including dangling links, so a nested folder cannot redirect a scaffold write.
check_path() {
  local base="$1" rel="$2" required="$3" current="$1" part i
  local parts=()
  IFS='/' read -r -a parts <<< "$rel"
  for ((i=0; i<${#parts[@]}; i++)); do
    part="${parts[$i]}"; current="$current/$part"
    [ ! -L "$current" ] || fail "Symlink in scaffold path: $current"
    if [ -e "$current" ]; then
      if [ "$i" -lt "$((${#parts[@]}-1))" ]; then
        [ -d "$current" ] || fail "Expected a directory: $current"
      else
        [ -f "$current" ] || fail "Expected a regular file: $current"
      fi
    elif [ "$required" = yes ]; then fail "Missing scaffold file: $base/$rel"; fi
  done
}
FILES=()
[ -f "$SRC/scaffold-files.txt" ] && [ ! -L "$SRC/scaffold-files.txt" ] || fail "Missing or linked scaffold manifest."
while IFS= read -r rel || [ -n "$rel" ]; do
  case "$rel" in ''|'#'*) continue ;; esac
  case "/$rel/" in *'/../'*|*'/./'*|*'//'*) fail "Unsafe path in scaffold manifest." ;; esac
  case "$rel" in /*|*\\*|*:*|.git|.git/*|*/.git|*/.git/*) fail "Unsafe path in scaffold manifest." ;; esac
  check_path "$SRC" "$rel" yes
  check_path "$DEST" "$rel" no
  FILES+=("$rel")
done < "$SRC/scaffold-files.txt"
[ "${#FILES[@]}" -gt 0 ] || fail "Scaffold manifest is empty."

# Existing vaults are never staged or committed, regardless of their ignore rules.
fresh=yes
if [ -d "$DEST" ] && [ -n "$(find "$DEST" -mindepth 1 -maxdepth 1 -print -quit)" ]; then fresh=no; fi
mkdir -p "$DEST"
installed=(); skipped=0
for rel in "${FILES[@]}"; do
  if [ -e "$DEST/$rel" ]; then
    skipped=$((skipped+1)); echo "Preserved existing file: $rel"; continue
  fi
  mkdir -p "$(dirname "$DEST/$rel")"
  # noclobber also refuses a file that appears after preflight.
  (set -C; cat "$SRC/$rel" > "$DEST/$rel")
  installed+=("$rel")
done
echo "Copied ${#installed[@]} scaffold files ($skipped existing files preserved)."

if [ "$SKIP_GIT" = "--skip-git" ] || ! command -v git >/dev/null 2>&1; then
  echo "Git skipped."
elif [ "$fresh" = no ] || [ -e "$DEST/.git" ] || [ -L "$DEST/.git" ] || git -C "$DEST" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Existing vault or Git checkout: no files staged or committed. Review additions and ignore rules yourself."
else
  (
    cd "$DEST"
    git init -b main -q
    git add -- "${installed[@]}"
    git commit -q -m "Second brain initialized from template"
  )
  echo "Local Git initialized with only the new scaffold files. Audit secrets before adding a remote."
fi

echo "Next: open the vault in Obsidian, then point Claude Code at it and run /ingest."
if [ "$skipped" -gt 0 ]; then
  echo "Review the listed collisions, especially CLAUDE.md, index.md and .gitignore, before using the new commands."
fi
