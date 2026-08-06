#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACK="$ROOT/rails-engineer"
failures=0

fail() {
  echo "FAIL: $1" >&2
  failures=$((failures + 1))
}

expect_no_matches() {
  local label="$1" pattern="$2"
  shift 2
  local matches
  matches=$(rg -n --glob '!docs/37signals-playbook/**' "$pattern" "$@" || true)
  if [ -n "$matches" ]; then
    fail "$label"
    printf '%s\n' "$matches" >&2
  fi
}

expect_no_matches "portable payload tokens" '\$ARGUMENTS|\$\{CLAUDE_PLUGIN_ROOT\}' "$PACK"
expect_no_matches "retired profile and pack references" 'CLAUDE\.md|## Application profile|rails-layered|rails-37signals' "$PACK"
expect_no_matches "bare collision skill references" '`(job-patterns|legacy-migration|mailer-patterns|migration-patterns|model-patterns|stimulus-patterns|turbo-patterns)`|/(job-patterns|legacy-migration|mailer-patterns|migration-patterns|model-patterns|stimulus-patterns|turbo-patterns)/SKILL\.md' "$PACK/skills"

for skill_file in "$PACK"/skills/*/SKILL.md; do
  skill_dir=$(basename "$(dirname "$skill_file")")
  skill_name=$(sed -n '2s/^name: //p' "$skill_file")
  [ "$skill_dir" = "$skill_name" ] || fail "skill directory/name mismatch: $skill_dir -> $skill_name"
done

duplicate_names=$(for skill_file in "$PACK"/skills/*/SKILL.md; do sed -n '2s/^name: //p' "$skill_file"; done | sort | uniq -d)
[ -z "$duplicate_names" ] || fail "duplicate skill names: $duplicate_names"

expect_no_matches "rich-model variants contain layered test guidance" 'RSpec|rspec|FactoryBot|factory_bot|layered-' "$PACK"/skills/rich-models-*

for skill_file in "$PACK"/skills/sdd-*/SKILL.md; do
  rg -q 'Read AGENTS\.md' "$skill_file" || fail "SDD skill does not read AGENTS profile: $skill_file"
  rg -q 'Workflow: conventional' "$skill_file" || fail "SDD skill does not exit to conventional workflow: $skill_file"
  rg -q 'rich-models' "$skill_file" || fail "SDD skill does not route rich-models work: $skill_file"
  rg -q 'bin/rails test' "$skill_file" || fail "SDD skill does not select Minitest command: $skill_file"
done

broken=$(find "$PACK" -type f -name '*.md' -print | while IFS= read -r file; do
  grep -oE '\]\([^)]+\.md[^)]*\)' "$file" | sed 's/^](//;s/)$//' | while IFS= read -r link; do
    case "$link" in http*|/*|\#*) continue ;; esac
    [ -e "$(dirname "$file")/${link%%#*}" ] || echo "$file -> $link"
  done
done)
[ -z "$broken" ] || fail "broken relative Markdown links: $broken"

if [ "$failures" -gt 0 ]; then
  exit 1
fi

echo 'PASS: plugin payload integrity'
