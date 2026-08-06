#!/usr/bin/env bash
# Verify the portable Rails Engineer payload and every host validator available
# on PATH. This is the release gate for local development and CI.
set -euo pipefail

cd "$(dirname "$0")/.."

PACK="rails-engineer"
failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

check_json() {
  jq empty \
    .claude-plugin/marketplace.json \
    .agents/plugins/marketplace.json \
    "$PACK/.claude-plugin/plugin.json" \
    "$PACK/.codex-plugin/plugin.json" \
    "$PACK/plugin.json" \
    "$PACK/specify/init-options.json"
}

check_marketplaces() {
  jq -e '
    (.plugins | length) == 1 and
    .plugins[0].name == "rails-engineer" and
    .plugins[0].source == "./rails-engineer"
  ' .claude-plugin/marketplace.json >/dev/null || fail "Claude marketplace must expose only ./rails-engineer"

  jq -e '
    (.plugins | length) == 1 and
    .plugins[0].name == "rails-engineer" and
    .plugins[0].source.source == "local" and
    .plugins[0].source.path == "./rails-engineer"
  ' .agents/plugins/marketplace.json >/dev/null || fail "Codex marketplace must expose only ./rails-engineer"
}

check_skills() {
  local skill name description names actual duplicates

  names=""
  while IFS= read -r skill; do
    name=$(sed -n '2,/^---$/p' "$skill" | sed -n 's/^name: *//p' | head -1)
    description=$(sed -n '2,/^---$/p' "$skill" | rg -m 1 '^description:' || true)

    if [ -z "$name" ]; then
      fail "$skill is missing frontmatter name"
    elif [ "$name" != "$(basename "$(dirname "$skill")")" ]; then
      fail "$skill name '$name' does not match its directory"
    fi

    if [ -z "$description" ]; then
      fail "$skill is missing frontmatter description"
    fi

    names="${names}${name}"$'\n'
  done < <(find "$PACK/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

  actual=$(printf '%s' "$names" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$actual" -eq 0 ]; then
    fail "$PACK has no skills"
  fi

  duplicates=$(printf '%s' "$names" | sed '/^$/d' | sort | uniq -d)
  if [ -n "$duplicates" ]; then
    fail "$PACK has duplicate skill names: $(echo "$duplicates" | tr '\n' ' ')"
  fi
}

check_portability() {
  local matches

  matches=$(rg -n --glob SKILL.md '\$ARGUMENTS|\$\{CLAUDE_PLUGIN_ROOT\}|(^|[[:space:]])!`' "$PACK" || true)
  if [ -n "$matches" ]; then
    echo "$matches" >&2
    fail "skill bodies contain a non-portable Claude-only substitution or load-time command"
  fi
}

check_links() {
  local file link target

  while IFS= read -r file; do
    while IFS= read -r link; do
      link=${link#](}
      link=${link%)}

      case "$link" in
        http*|/*|\#*) continue ;;
      esac

      target="$(dirname "$file")/${link%%#*}"
      if [ ! -e "$target" ]; then
        fail "broken Markdown link: $file -> $link"
      fi
    done < <(rg -o '\]\([^)]+\.md[^)]*\)' "$file" || true)
  done < <(find . -path ./.git -prune -o -type f -name '*.md' -print)
}

check_host_validators() {
  if command -v claude >/dev/null 2>&1; then
    claude plugin validate --strict "./$PACK"
  else
    echo "SKIP: Claude Code is not installed"
  fi

  if command -v agy >/dev/null 2>&1; then
    agy plugin validate "./$PACK"
  else
    echo "SKIP: Antigravity CLI is not installed"
  fi
}

check_json
check_marketplaces
scripts/check_versions.sh
check_skills
check_portability
check_links
check_host_validators

if [ "$failures" -gt 0 ]; then
  exit 1
fi

echo "Plugin verification passed"
