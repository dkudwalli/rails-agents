#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACK="$ROOT/rails-engineer"
failures=0

fail() {
  echo "FAIL: $1" >&2
  failures=$((failures + 1))
}

assert_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected verifier output to contain: $needle"
}

verification_fixture() {
  local path="$probe_root/verifier-fixture"

  mkdir -p "$path/.agents"
  cp -a "$ROOT/.claude-plugin" "$path/.claude-plugin"
  cp -a "$ROOT/.agents/plugins" "$path/.agents/plugins"
  cp -a "$ROOT/rails-engineer" "$path/rails-engineer"
  cp -a "$ROOT/scripts" "$path/scripts"
  cp "$ROOT/AGENTS.md" "$path/AGENTS.md"
  cp "$ROOT/README.md" "$path/README.md"
  cp "$ROOT/CHANGELOG.md" "$path/CHANGELOG.md"
  cp -a "$ROOT/docs" "$path/docs"

  printf '%s' "$path"
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
find_stale_internal_pointers() {
  local pack="${1:-$PACK}"
  rg -n --pcre2 '(?<!\.claude/)rules/[a-z0-9_-]+\.md|(?<!plugin>/)skills/[a-z0-9_-]+' "$pack/skills" --glob '*.md' || true
}

stale_internal_pointers=$(find_stale_internal_pointers)
[ -z "$stale_internal_pointers" ] || fail "stale internal payload pointers: $stale_internal_pointers"

find_unqualified_collision_calls() {
  local pack="${1:-$PACK}"
  rg -n --pcre2 '(?<![a-z-])(job-patterns|legacy-migration|mailer-patterns|migration-patterns|model-patterns|stimulus-patterns|turbo-patterns)(?![a-z-]|\.md)' "$pack/skills" --glob '*.md' || true
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

guide="$PACK/skills/rails-guide/SKILL.md"
[ -f "$guide" ] || fail "rails-guide skill is missing"
rg -q '^name: rails-guide$' "$guide" || fail "rails-guide frontmatter name is invalid"
rg -q '^user-invocable: true$' "$guide" || fail "rails-guide must be user-invocable"
rg -q 'Read the target application.s `AGENTS\.md`' "$guide" || fail "rails-guide is not profile-first"
rg -q '`rails-onboard` and stop' "$guide" || fail "rails-guide does not route missing profiles to onboarding"
for router in rails-workflow rails-architecture rails-models rails-testing rails-css rails-database rails-access rails-runtime rails-frontend rails-tenancy rails-deployment; do
  rg -q "\`$router\`" "$guide" || fail "rails-guide does not expose $router"
done

architecture="$PACK/skills/rails-architecture/SKILL.md"
rg -q 'layered-rails-architecture' "$architecture" || fail "rails-architecture does not route layered work to its architecture skill"
rg -q 'rich-models-rails-architecture' "$architecture" || fail "rails-architecture does not route rich-models work to its architecture skill"

rich_architecture="$PACK/skills/rich-models-rails-architecture/SKILL.md"
[ -f "$rich_architecture" ] || fail "rich-models architecture skill is missing"
rg -q '^name: rich-models-rails-architecture$' "$rich_architecture" || fail "rich-models architecture skill frontmatter name is invalid"
rg -q 'Read the target application.s `AGENTS\.md`' "$rich_architecture" || fail "rich-models architecture skill is not profile-first"
rg -q 'recorded deliberate divergence' "$rich_architecture" || fail "rich-models architecture skill does not preserve recorded divergences"
for specialist in 37signals-conventions rich-models-model-patterns concern-patterns state-records crud-patterns; do
  rg -q "\`$specialist\`" "$rich_architecture" || fail "rich-models architecture skill does not route to $specialist"
done
rg -q 'app/services' "$rich_architecture" || fail "rich-models architecture skill does not reject category layers by default"

onboard="$PACK/skills/rails-onboard/SKILL.md"
for starting_stack in 'Layered' 'Rich Models — Fizzy-style' 'Rich Models — ONCE-compatible'; do
  rg -Fq "$starting_stack" "$onboard" || fail "rails-onboard does not expose the $starting_stack starting stack"
done
rg -q 'candidate profile' "$onboard" || fail "rails-onboard does not present an editable candidate"
rg -q 'Ask for explicit confirmation' "$onboard" || fail "rails-onboard lost its write confirmation"

# Bodies and references only. Each description now names its layered sibling in a WHEN NOT handoff,
# which is a profile boundary rather than layered guidance leaking into the rich-models payload.
LAYERED_LEAK='RSpec|rspec|FactoryBot|factory_bot|layered-'

for rich_skill in "$PACK"/skills/rich-models-*/SKILL.md; do
  body_matches=$(awk '/^---$/ { seen++; next } seen >= 2' "$rich_skill" |
    rg -n "$LAYERED_LEAK" || true)
  if [ -n "$body_matches" ]; then
    fail "rich-model variant body contains layered test guidance: $rich_skill"
    printf '%s\n' "$body_matches" >&2
  fi
done

reference_matches=$(find "$PACK/skills" -path '*/rich-models-*/references/*' -type f \
  -exec rg -n "$LAYERED_LEAK" {} + || true)
if [ -n "$reference_matches" ]; then
  fail "rich-model reference files contain layered test guidance"
  printf '%s\n' "$reference_matches" >&2
fi

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
  local pack="${1:-$PACK}"
  find "$pack" -type f -name '*.md' -print | while IFS= read -r file; do
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

probe_root=$(mktemp -d)
trap 'rm -rf "$probe_root"' EXIT HUP INT TERM
mkdir -p "$probe_root/skills/rails-models"
probe_target="$probe_root/skills/rails-models/SKILL.md"
cp "$PACK/skills/rails-models/SKILL.md" "$probe_target"
printf '\nRegression probe: route this to model-patterns.\n' >> "$probe_target"
if [ -z "$(find_unqualified_collision_calls "$probe_root")" ]; then
  fail "collision detector missed deliberate temporary mutation"
fi
printf '\nRegression probe: see rules/views.md.\n' >> "$probe_target"
if [ -z "$(find_stale_internal_pointers "$probe_root")" ]; then
  fail "stale-pointer detector missed deliberate temporary mutation"
fi
printf '\nRegression probe: see `../../../missing-profile/AGENTS.md`.\n' >> "$probe_target"
if [ -z "$(relative_targets "$probe_root" | while IFS=$'\t' read -r file target; do path=${target%%#*}; [ -e "$(dirname "$file")/$path" ] || echo "$file -> $target"; done)" ]; then
  fail "inline-code path detector missed deliberate temporary mutation"
fi

# Exercise the release verifier against a temporary payload carrying one mutation for every
# portable-skill contract. Each assertion names the diagnostic the corresponding production check
# must emit; a generic non-zero exit is not enough because another mutation could cause it.
limit_fixture=$(verification_fixture)
limit_skill="$limit_fixture/rails-engineer/skills/pr-artifact/SKILL.md"
limit_boundary="WHEN NOT: skip this workflow"
limit_padding=$((1024 - ${#limit_boundary} - 1))
limit_description="$(printf 'x%.0s' $(seq 1 "$limit_padding")) $limit_boundary"
# Move the description below every other key instead of deleting one: the check under test reads
# from `description:` to the next top-level key, and dropping `user-invocable` here would strand the
# skill from the reachability closure, failing on the wrong contract.
sed -i '/^description:/d' "$limit_skill"
sed -i "/^user-invocable: true$/a description: $limit_description" "$limit_skill"

set +e
limit_output=$(cd "$limit_fixture" && scripts/verify_plugins.sh 2>&1)
limit_status=$?
set -e

assert_contains "$limit_description" "WHEN NOT:"
[ "${#limit_description}" -eq 1024 ] || fail "last-key description fixture is not at the 1024-character limit"
[ "$limit_status" -eq 0 ] || fail "a 1024-character last-key description was rejected: $limit_output"

fixture=$(verification_fixture)
guide="$fixture/rails-engineer/skills/rails-guide/SKILL.md"
workflow="$fixture/rails-engineer/skills/rails-workflow/SKILL.md"
performance="$fixture/rails-engineer/skills/performance-optimization/SKILL.md"
performance_n_plus_one="$fixture/rails-engineer/skills/performance-optimization/references/n-plus-one.md"
accessibility="$fixture/rails-engineer/skills/accessibility-review/SKILL.md"
accessibility_failures="$fixture/rails-engineer/skills/accessibility-review/references/common-failures.md"
accessibility_snippets="$fixture/rails-engineer/skills/accessibility-review/references/rails-snippets.md"
frontend="$fixture/rails-engineer/skills/rails-frontend/SKILL.md"
service_patterns="$fixture/rails-engineer/skills/service-patterns/SKILL.md"
tailwind="$fixture/rails-engineer/skills/tailwind-patterns/SKILL.md"

printf '\nRegression probe: use imaginary-agent and @ghost-agent.\n' >> "$guide"
printf '\nRegression probe: use reference-only-agent.\n' >> \
  "$fixture/rails-engineer/skills/caching-patterns/references/http-caching.md"
printf '\nRegression probe: see @references/missing.md.\n' >> "$guide"
for key in agent model context allowed-tools effort; do
  sed -i "/^description:/i $key: unsupported" "$guide"
done
sed -i 's/rails-guide/Invalid_Skill_Name/' "$guide"
sed -i 's/ WHEN NOT:.*//' "$workflow"
long_description=$(printf 'x%.0s' {1..1100})
sed -i "s|^description:.*|description: $long_description|" "$fixture/rails-engineer/skills/pr-artifact/SKILL.md"
sed -i 's/ships 92 portable skills/ships 91 portable skills/' "$fixture/README.md"
printf '\nRegression probe: run specs, then re-run specs.\n' >> "$performance"
sed -i '/Testing: minitest.*rails-testing/d' "$performance_n_plus_one"
printf '\nRegression probe: axe-core specs run in CI.\n' >> "$accessibility"
sed -i '/Profile adaptation:.*rails-testing.*rails-css.*rails-frontend/d' "$accessibility_failures"
sed -i '/Profile routing:.*rails-testing.*rails-css.*rails-frontend/d' "$accessibility_snippets"
# rails-frontend carries the only inbound edge to i18n-patterns; severing it must strand the skill.
sed -i 's/select i18n-patterns/select the locale reference/' "$frontend"
# Strip the profile boundary from one skill on each guarded axis. Without these the two halves of a
# profile choice can match the same trigger words and hand an app the other stack's guidance.
sed -i 's/ Applies only in a layered profile app\.//' "$service_patterns"
sed -i 's/ Applies only in a tailwind profile app\.//' "$tailwind"

set +e
verifier_output=$(cd "$fixture" && scripts/verify_plugins.sh 2>&1)
verifier_status=$?
set -e

[ "$verifier_status" -ne 0 ] || fail "portable payload mutations unexpectedly passed verification"
assert_contains "$verifier_output" "legacy agent reference in rails-guide/SKILL.md: imaginary-agent"
assert_contains "$verifier_output" "legacy agent reference in rails-guide/SKILL.md: @ghost-agent"
assert_contains "$verifier_output" "legacy agent reference in caching-patterns/references/http-caching.md: reference-only-agent"
assert_contains "$verifier_output" "legacy reference pointer in rails-guide/SKILL.md: @references/missing.md"
for key in agent model context allowed-tools effort; do
  assert_contains "$verifier_output" "rails-guide/SKILL.md has non-portable frontmatter key: $key"
done
assert_contains "$verifier_output" "skill name 'Invalid_Skill_Name' is invalid"
assert_contains "$verifier_output" "rails-workflow/SKILL.md description is missing a meaningful WHEN NOT boundary"
assert_contains "$verifier_output" "pr-artifact/SKILL.md description exceeds 1024 characters"
assert_contains "$verifier_output" "README.md documents 91 skills but the payload contains 92"
assert_contains "$verifier_output" "performance-optimization/SKILL.md contains unguarded RSpec-specific workflow wording"
assert_contains "$verifier_output" "performance-optimization/references/n-plus-one.md does not route Testing: minitest through rails-testing"
assert_contains "$verifier_output" "accessibility-review/SKILL.md contains unguarded axe-core specs wording"
assert_contains "$verifier_output" "accessibility-review/references/common-failures.md lacks profile adaptation through rails-testing, rails-css, and rails-frontend"
assert_contains "$verifier_output" "accessibility-review/references/rails-snippets.md lacks profile routing through rails-testing, rails-css, and rails-frontend"
assert_contains "$verifier_output" "unreachable skill: i18n-patterns is named by no router or reachable skill and is not user-invocable"
assert_contains "$verifier_output" "service-patterns/SKILL.md is profile-bound but its description never says it applies only in a layered profile app"
assert_contains "$verifier_output" "tailwind-patterns/SKILL.md is profile-bound but its description never says it applies only in a tailwind profile app"

if [ "$failures" -gt 0 ]; then
  exit 1
fi

echo 'PASS: plugin payload integrity'
