#!/usr/bin/env bash
# Second Brain Template - installer (macOS / Linux)
#
# Usage:
#   ./install.sh /path/to/MyVault
#   ./install.sh /path/to/MyVault --skip-git
#
# Copies the template scaffold into your chosen vault folder, initializes local
# git (optional), and prints the getting-started steps. Never touches the
# network, never overwrites existing files.

set -euo pipefail

DEST="${1:-}"
SKIP_GIT="${2:-}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$DEST" ]; then
  echo "Usage: ./install.sh /path/to/MyVault [--skip-git]"
  exit 1
fi

echo ""
echo "Second Brain Template installer"
echo "Source:      $SRC"
echo "Destination: $DEST"
echo ""

# 1. Destination
mkdir -p "$DEST"
echo "[1/4] Destination ready"

# 2. Copy scaffold (skip installers + git internals; never overwrite)
copied=0; skipped=0
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  case "$rel" in
    install.ps1|install.sh|.git/*) continue ;;
  esac
  target="$DEST/$rel"
  if [ -e "$target" ]; then skipped=$((skipped+1)); continue; fi
  mkdir -p "$(dirname "$target")"
  cp "$f" "$target"
  copied=$((copied+1))
done < <(find "$SRC" -type f -not -path "$SRC/.git/*" -print0)
echo "[2/4] Copied $copied files ($skipped already existed, left untouched)"

# 3. Local git (undo/history safety net - LOCAL only; see the README before adding any remote)
if [ "$SKIP_GIT" != "--skip-git" ] && command -v git >/dev/null 2>&1; then
  if [ ! -d "$DEST/.git" ]; then
    (cd "$DEST" && git init -b main -q && git add . && git commit -q -m "Second brain initialized from template")
    echo "[3/4] Local git initialized (1 commit). Do NOT push to a public remote before a secrets audit."
  else
    echo "[3/4] Git repo already present - untouched"
  fi
else
  echo "[3/4] Git skipped"
fi

# 4. Next steps
echo "[4/4] Done."
echo ""
echo "Next steps:"
echo "  1. Open $DEST as a vault in Obsidian (free) - File > Open folder as vault"
echo "  2. Point Claude Code at the folder:  cd \"$DEST\"  then run  claude"
echo "     (it reads CLAUDE.md automatically and becomes your librarian)"
echo "  3. Look at the example- pages in wiki/ to see the shape, then delete them"
echo "  4. Drop your first sources into raw/ and run /ingest"
echo ""
