#!/usr/bin/env bash
# Verify the portable plugin payload and every host validator available on PATH.
#
# This is the release gate for local development and CI. It intentionally does
# not install or configure host CLIs; CI owns lifecycle smoke tests in its own
# disposable runner home.
set -euo pipefail

cd "$(dirname "$0")/.."

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

check_json() {
  jq empty \
    .claude-plugin/marketplace.json \
    .agents/plugins/marketplace.json \
    rails-*/.claude-plugin/plugin.json \
    rails-*/.codex-plugin/plugin.json \
    rails-*/plugin.json \
    rails-*/hooks/hooks.json \
    rails-layered/specify/init-options.json
}

check_skills() {
  local pack skill name description names expected actual duplicates

  for pack in rails-layered rails-37signals; do
    names=""
    expected=24
    if [ "$pack" = "rails-layered" ]; then
      expected=54
    fi

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
    done < <(find "$pack/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

    actual=$(printf '%s' "$names" | sed '/^$/d' | wc -l | tr -d ' ')
    if [ "$actual" -ne "$expected" ]; then
      fail "$pack has $actual skills; expected $expected"
    fi

    duplicates=$(printf '%s' "$names" | sed '/^$/d' | sort | uniq -d)
    if [ -n "$duplicates" ]; then
      fail "$pack has duplicate skill names: $(echo "$duplicates" | tr '\n' ' ')"
    fi
  done
}

check_portability() {
  local matches

  matches=$(rg -n --glob SKILL.md '\$ARGUMENTS|\$\{CLAUDE_PLUGIN_ROOT\}|(^|[[:space:]])!`' rails-layered rails-37signals || true)
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
    claude plugin validate --strict ./rails-layered
    claude plugin validate --strict ./rails-37signals
  else
    echo "SKIP: Claude Code is not installed"
  fi

  if command -v agy >/dev/null 2>&1; then
    agy plugin validate ./rails-layered
    agy plugin validate ./rails-37signals
  else
    echo "SKIP: Antigravity CLI is not installed"
  fi
}

check_json
scripts/check_versions.sh
check_skills
check_portability
check_links
check_host_validators

if [ "$failures" -gt 0 ]; then
  exit 1
fi

echo "Plugin verification passed"
