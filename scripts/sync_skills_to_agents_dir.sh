#!/usr/bin/env bash
# Rebuild .agents/skills as symlinks to the portable Rails Engineer skill tree.
#
# Usage: scripts/sync_skills_to_agents_dir.sh
#
# This mirror is for using a clone of this repository with Antigravity or
# opencode. Plugin installation is the normal Claude Code and Codex path. The
# mirror is intentionally unprefixed: every skill directory matches its
# frontmatter name, so host discovery remains deterministic.
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "Usage: $0" >&2
  exit 1
fi

cd "$(dirname "$0")/.."
PACK="rails-engineer"
SRC="$PACK/skills"
DEST=".agents/skills"

[ -d "$SRC" ] || { echo "No such plugin skill tree: $SRC" >&2; exit 1; }

rm -rf "$DEST"
mkdir -p "$DEST"
for dir in "$SRC"/*/; do
  name=$(basename "$dir")
  ln -s "../../$SRC/$name" "$DEST/$name"
done

echo "Mirrored $(find "$DEST" -maxdepth 1 -type l | wc -l | tr -d ' ') skills from $PACK into $DEST"
