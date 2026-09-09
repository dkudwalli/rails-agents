#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
failures=0

fail() {
  echo "FAIL: $1" >&2
  failures=$((failures + 1))
}

assert_contains() {
  [[ "$1" == *"$2"* ]] || fail "expected verifier output to contain: $2"
}

fixture() {
  local path="$TMPDIR/$1"
  mkdir -p "$path/.agents"
  cp -a "$ROOT/.claude-plugin" "$path/.claude-plugin"
  cp -a "$ROOT/.agents/plugins" "$path/.agents/plugins"
  cp -a "$ROOT/rails-engineer" "$path/rails-engineer"
  cp -a "$ROOT/scripts" "$path/scripts"
  cp "$ROOT/README.md" "$ROOT/CHANGELOG.md" "$ROOT/AGENTS.md" "$path/"
  printf '%s' "$path"
}

test_baseline_passes() {
  local path
  path=$(fixture baseline)
  (cd "$path" && RAILS_ENGINEER_SKIP_HOST_VALIDATORS=1 scripts/verify_plugins.sh) ||
    fail "focused payload did not pass verification"
}

test_invalid_skill_name_fails() {
  local path output status
  path=$(fixture invalid-skill)
  sed -i 's/^name: rails-guide$/name: Invalid_Name/' "$path/rails-engineer/skills/rails-guide/SKILL.md"
  set +e
  output=$(cd "$path" && RAILS_ENGINEER_SKIP_HOST_VALIDATORS=1 scripts/verify_plugins.sh 2>&1)
  status=$?
  set -e
  [ "$status" -ne 0 ] || fail "invalid skill name unexpectedly passed"
  assert_contains "$output" "directory/name mismatch"
}

test_missing_router_target_fails() {
  local path output status
  path=$(fixture missing-route)
  sed -i 's/channel-bay-testing/not-a-channel-bay-skill/' "$path/rails-engineer/skills/rails-guide/SKILL.md"
  set +e
  output=$(cd "$path" && RAILS_ENGINEER_SKIP_HOST_VALIDATORS=1 scripts/verify_plugins.sh 2>&1)
  status=$?
  set -e
  [ "$status" -ne 0 ] || fail "missing router target unexpectedly passed"
  assert_contains "$output" "rails-guide must route to channel-bay-testing"
}

test_missing_boundary_fails() {
  local path output status
  path=$(fixture missing-boundary)
  sed -i 's/ WHEN NOT:.*//' "$path/rails-engineer/skills/channel-bay-backend/SKILL.md"
  set +e
  output=$(cd "$path" && RAILS_ENGINEER_SKIP_HOST_VALIDATORS=1 scripts/verify_plugins.sh 2>&1)
  status=$?
  set -e
  [ "$status" -ne 0 ] || fail "missing boundary unexpectedly passed"
  assert_contains "$output" "missing a WHEN NOT boundary"
}

test_router_without_invoke_instruction_fails() {
  local path output status
  path=$(fixture no-invoke)
  # Naming the specialists is not routing to them. Strip every invoke instruction while leaving
  # the table itself intact — the payload must not pass on a table of bare skill names.
  sed -i 's/[Ii]nvoke/name/g' "$path/rails-engineer/skills/rails-guide/SKILL.md"
  set +e
  output=$(cd "$path" && RAILS_ENGINEER_SKIP_HOST_VALIDATORS=1 scripts/verify_plugins.sh 2>&1)
  status=$?
  set -e
  [ "$status" -ne 0 ] || fail "router without an invoke instruction unexpectedly passed"
  assert_contains "$output" "must tell the agent to invoke the routed skill"
}

test_missing_absent_source_clause_fails() {
  local path output status
  path=$(fixture no-absent-source)
  # The clause wraps onto a second line; drop both.
  sed -i '/gitignored; if it is absent/,+1d' \
    "$path/rails-engineer/skills/channel-bay-backend/SKILL.md"
  set +e
  output=$(cd "$path" && RAILS_ENGINEER_SKIP_HOST_VALIDATORS=1 scripts/verify_plugins.sh 2>&1)
  status=$?
  set -e
  [ "$status" -ne 0 ] || fail "skill citing AGENTS.md without the absent-source clause passed"
  assert_contains "$output" "cites AGENTS.md without the absent-source clause"
}

test_retired_host_payload_fails() {
  local path output status
  path=$(fixture retired-host)
  printf '{}\n' > "$path/rails-engineer/plugin.json"
  set +e
  output=$(cd "$path" && RAILS_ENGINEER_SKIP_HOST_VALIDATORS=1 scripts/verify_plugins.sh 2>&1)
  status=$?
  set -e
  [ "$status" -ne 0 ] || fail "retired host payload unexpectedly passed"
  assert_contains "$output" "retired host/profile payload remains"
}

test_baseline_passes
test_invalid_skill_name_fails
test_missing_router_target_fails
test_missing_boundary_fails
test_router_without_invoke_instruction_fails
test_missing_absent_source_clause_fails
test_retired_host_payload_fails

if [ "$failures" -gt 0 ]; then
  echo "FAIL: $failures assertion(s) failed" >&2
  exit 1
fi

echo "PASS: focused plugin payload contract"
