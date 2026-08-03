#!/usr/bin/env bash
# Rebuild .agents/skills as a symlink mirror of ONE pack's skills.
#
# Usage: scripts/sync_skills_to_agents_dir.sh <layered|37signals>
#
# The two packs are mutually exclusive and six skills now exist in both
# (job-patterns, mailer-patterns, migration-patterns, model-patterns,
# stimulus-patterns, turbo-patterns) with deliberately opposite advice. Skill
# discovery reads the frontmatter `name:`, so mirroring both packs at once makes
# those six ambiguous. One pack at a time, unprefixed, so the directory name equals the
# frontmatter name exactly as it does in the pack itself.
#
# Codex and Claude Code users install the plugin instead — this mirror is for
# working from a clone of this repo, and for tools that read .agents/skills
# directly. Antigravity and opencode both do: they discover
# {workspace}/.agents/skills/<name>/SKILL.md with no install step, so running
# this script is a complete workspace-scoped install of the selected pack.
#
# It only covers a clone of THIS repo — the mirror is written here, and both
# tools stop walking up at the git worktree root. From another project, point
# opencode's skills.paths at rails-<pack>/skills instead.
set -euo pipefail

PACK="${1:-}"
case "$PACK" in
  layered|37signals) ;;
  *) echo "Usage: $0 <layered|37signals>" >&2; exit 1 ;;
esac

cd "$(dirname "$0")/.."
SRC="rails-$PACK/skills"
DEST=".agents/skills"

[ -d "$SRC" ] || { echo "No such pack: $SRC" >&2; exit 1; }

rm -rf "$DEST"
mkdir -p "$DEST"
for dir in "$SRC"/*/; do
  name=$(basename "$dir")
  ln -s "../../$SRC/$name" "$DEST/$name"
done

echo "Mirrored $(find "$DEST" -maxdepth 1 -type l | wc -l) skills from rails-$PACK into $DEST"
