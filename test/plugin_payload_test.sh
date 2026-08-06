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
expect_no_matches "pack-owned AGENTS profile references" '(?:this|the) pack.s .*AGENTS\.md' "$PACK/skills"
find_unqualified_collision_calls() {
  rg -n --pcre2 '(?<![a-z-])(job-patterns|legacy-migration|mailer-patterns|migration-patterns|model-patterns|stimulus-patterns|turbo-patterns)(?![a-z-]|\.md)' "$PACK/skills" --glob '*.md' || true
}

collision_calls=$(find_unqualified_collision_calls)
[ -z "$collision_calls" ] || fail "unqualified retired collision skill identifiers: $collision_calls"

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
  profile_line=$(rg -n -m 1 'Profile routing' "$skill_file" | cut -d: -f1)
  first_instruction_line=$(awk 'NR > 1 && /^---$/ { body = 1; next } body && NF { print NR; exit }' "$skill_file")
  incompatible_line=$(awk 'NR > 8 && /bundle exec rspec|app\/services|app\/policies|app\/components|ViewComponent|Tailwind/ && $0 !~ /Testing: rspec|Architecture: layered|profile-selected|selected profile|layered profile/ { print NR; exit }' "$skill_file")
  if [ -z "$profile_line" ] || [ "$profile_line" != "$first_instruction_line" ]; then
    fail "SDD profile routing is not the first instruction: $skill_file"
  fi
  if [ -n "$incompatible_line" ]; then
    fail "SDD contains unguarded incompatible instruction after profile routing: $skill_file:$incompatible_line"
  fi
done

relative_targets() {
  find "$PACK" -type f -name '*.md' -print | while IFS= read -r file; do
    grep -oE '\]\([^)]+\)' "$file" | sed 's/^](//;s/)$//' | while IFS= read -r target; do
      case "$target" in ../*|./*) printf '%s\t%s\n' "$file" "$target" ;; esac
    done
    perl -ne 'while (/`([^`]+)`/g) { $target = $1; print "$ARGV\t$target\n" if $target =~ m{^(?:\.\.?/)+[^[:space:]`]+(?:\.md|AGENTS\.md|CLAUDE\.md)(?:#[^[:space:]`]+)?$}; }' "$file"
  done
}

broken=$(relative_targets | while IFS=$'\t' read -r file target; do
  path=${target%%#*}
  [ -e "$(dirname "$file")/$path" ] || echo "$file -> $target"
done)
[ -z "$broken" ] || fail "broken relative Markdown and inline-code paths: $broken"

profile_path_refs=$(rg -n '`?(\.\./|\./)+AGENTS\.md|`?(\.\./|\./)+CLAUDE\.md' "$PACK" --glob '*.md' || true)
[ -z "$profile_path_refs" ] || fail "relative references to nonexistent pack profile files: $profile_path_refs"

probe_target="$PACK/skills/rails-models/SKILL.md"
probe_backup=$(mktemp)
cp "$probe_target" "$probe_backup"
trap 'cp "$probe_backup" "$probe_target"; rm -f "$probe_backup"' EXIT HUP INT TERM
printf '\nRegression probe: route this to model-patterns.\n' >> "$probe_target"
if [ -z "$(find_unqualified_collision_calls)" ]; then
  fail "collision detector missed deliberate temporary mutation"
fi
printf '\nRegression probe: see `../../../missing-profile/AGENTS.md`.\n' >> "$probe_target"
if [ -z "$(relative_targets | while IFS=$'\t' read -r file target; do path=${target%%#*}; [ -e "$(dirname "$file")/$path" ] || echo "$file -> $target"; done)" ]; then
  fail "inline-code path detector missed deliberate temporary mutation"
fi
cp "$probe_backup" "$probe_target"

if [ "$failures" -gt 0 ]; then
  exit 1
fi

echo 'PASS: plugin payload integrity'
