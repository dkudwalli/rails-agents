#!/usr/bin/env bash
# Verify the portable Rails Engineer payload and every host validator available
# on PATH. This is the release gate for local development and CI.
set -euo pipefail

cd "$(dirname "$0")/.."

PACK="rails-engineer"
failures=0

# Skills bound to one value of the profile's *Architecture* field. Their descriptions must say so,
# and must name the sibling skill the other architecture uses instead, so an agent cannot load
# contradictory advice by matching trigger words alone. Add a skill here when it becomes
# architecture-bound; the gate below then fails until its description is written.
#
# Membership is the Architecture axis only. Deliberately absent:
#   - Skills selected by a different profile field, which is a separate choice with its own
#     router: CSS (tailwind-patterns, css-design), Authorization (policy-patterns, crud-patterns),
#     Runtime, Database, Tenancy, Deployment.
#   - testing-patterns and rspec-patterns, gated on the suite already in the repo. That is an
#     observable signal and a better one than the profile file; leave their phrasing alone.
#   - caching-patterns, caching-strategies, and 37signals-conventions, which carry an equivalent
#     gate in their own wording and predate this check. Listing them would fail on phrasing, not
#     on a missing boundary.
LAYERED_ONLY_SKILLS="
layered-conventions
layered-job-patterns
layered-legacy-migration
layered-mailer-patterns
layered-migration-patterns
layered-model-patterns
layered-rails-architecture
layered-stimulus-patterns
layered-turbo-patterns
form-patterns
presenter-patterns
query-patterns
rails-concern
service-patterns
"

RICH_MODELS_ONLY_SKILLS="
rich-models-job-patterns
rich-models-legacy-migration
rich-models-mailer-patterns
rich-models-migration-patterns
rich-models-model-patterns
rich-models-rails-architecture
rich-models-stimulus-patterns
rich-models-turbo-patterns
concern-patterns
implementation-workflow
state-records
"

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

contains() {
  case "$2" in *"$1"*) return 0 ;; esac
  return 1
}

# A profile-bound skill must scope itself to its own profile and hand the other profile off to its
# sibling by name. Routers enforce this in prose, but nothing stops an agent from matching a leaf
# description directly, and the two profiles give contradictory advice under the same keywords.
check_profile_gate() {
  local skill="$1" name="$2" description="$3" own opposite

  if contains " $name " " $(echo "$LAYERED_ONLY_SKILLS" | tr '\n' ' ') "; then
    own="layered"
    opposite="rich-models"
  elif contains " $name " " $(echo "$RICH_MODELS_ONLY_SKILLS" | tr '\n' ' ') "; then
    own="rich-models"
    opposite="layered"
  else
    return 0
  fi

  if ! contains "$own profile" "$description"; then
    fail "$skill is profile-bound but its description never says it applies only in a $own profile app"
  fi

  if ! contains "WHEN NOT: A $opposite profile app — use " "$description"; then
    fail "$skill is missing its 'WHEN NOT: A $opposite profile app — use <sibling>.' gate"
  fi
}

# Descriptions are folded YAML, so the clause the profile gate looks for is usually on a
# continuation line. Read from `description:` up to the next top-level key, not just the first line.
skill_description() {
  sed -n '2,/^---$/p' "$1" |
    awk '/^description:/ { found = 1 }
         found && /^---$/ { exit }
         found && !/^description:/ && /^[A-Za-z][A-Za-z0-9_-]*:/ { exit }
         found' |
    tr '\n' ' ' |
    sed -e 's/^description: *[>|]\{0,1\}-\{0,1\} *//' -e 's/  */ /g' -e 's/ *$//'
}

check_skills() {
  local skill name description names actual duplicates boundary documented

  names=""
  while IFS= read -r skill; do
    name=$(sed -n '2,/^---$/p' "$skill" | sed -n 's/^name: *//p' | head -1)
    description=$(skill_description "$skill")

    if [ -z "$name" ]; then
      fail "$skill is missing frontmatter name"
    elif [ "$name" != "$(basename "$(dirname "$skill")")" ]; then
      fail "$skill name '$name' does not match its directory"
    fi

    if [ -n "$name" ] && { [ "${#name}" -gt 64 ] || [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; }; then
      fail "skill name '$name' is invalid in ${skill#"$PACK/skills/"}: use 1-64 lowercase letters, numbers, and single hyphens"
    fi

    if [ -z "$description" ]; then
      fail "$skill is missing frontmatter description"
    else
      if [ "${#description}" -gt 1024 ]; then
        fail "${skill#"$PACK/skills/"} description exceeds 1024 characters"
      fi

      if [[ "$description" != *"WHEN NOT:"* ]]; then
        fail "${skill#"$PACK/skills/"} description is missing a meaningful WHEN NOT boundary"
      else
        boundary=${description#*WHEN NOT:}
        boundary=${boundary#"${boundary%%[![:space:]]*}"}
        if [ "${#boundary}" -lt 12 ]; then
          fail "${skill#"$PACK/skills/"} description is missing a meaningful WHEN NOT boundary"
        fi
      fi

      check_profile_gate "$skill" "$name" "$description"
    fi

    names="${names}${name}"$'\n'
  done < <(find "$PACK/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

  actual=$(printf '%s' "$names" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$actual" -eq 0 ]; then
    fail "$PACK has no skills"
  fi

  documented=$(sed -n 's/.*ships \([0-9][0-9]*\) portable skills.*/\1/p' README.md)
  if [ -z "$documented" ]; then
    fail "README.md does not document the portable skill count"
  elif [ "$documented" != "$actual" ]; then
    fail "README.md documents $documented skills but the payload contains $actual"
  fi

  duplicates=$(printf '%s' "$names" | sed '/^$/d' | sort | uniq -d)
  if [ -n "$duplicates" ]; then
    fail "$PACK has duplicate skill names: $(echo "$duplicates" | tr '\n' ' ')"
  fi
}

check_portability() {
  local matches skill key file line token

  matches=$(rg -n --glob SKILL.md '\$ARGUMENTS|\$\{CLAUDE_PLUGIN_ROOT\}|(^|[[:space:]])!`' "$PACK" || true)
  if [ -n "$matches" ]; then
    echo "$matches" >&2
    fail "skill bodies contain a non-portable Claude-only substitution or load-time command"
  fi

  while IFS= read -r skill; do
    for key in agent model context allowed-tools effort; do
      if sed -n '2,/^---$/p' "$skill" | rg -q "^$key:"; then
        fail "${skill#"$PACK/skills/"} has non-portable frontmatter key: $key"
      fi
    done
  done < <(find "$PACK/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

  while IFS=: read -r file line token; do
    fail "legacy agent reference in ${file#"$PACK/skills/"}: $token"
  done < <(rg --pcre2 -n -o --glob '*.md' '@?[a-z0-9]+(?:-[a-z0-9]+)*-agent(?![a-z0-9-])' "$PACK/skills" || true)

  while IFS=: read -r file line token; do
    fail "legacy reference pointer in ${file#"$PACK/skills/"}: $token"
  done < <(rg -n -o --glob '*.md' '@references/[a-zA-Z0-9_./-]+' "$PACK/skills" || true)
}

check_profiled_review_guidance() {
  local performance performance_n_plus_one accessibility accessibility_failures accessibility_snippets

  performance="$PACK/skills/performance-optimization/SKILL.md"
  performance_n_plus_one="$PACK/skills/performance-optimization/references/n-plus-one.md"
  accessibility="$PACK/skills/accessibility-review/SKILL.md"
  accessibility_failures="$PACK/skills/accessibility-review/references/common-failures.md"
  accessibility_snippets="$PACK/skills/accessibility-review/references/rails-snippets.md"

  if rg -qi '\b(?:run|re-run) specs\b' "$performance"; then
    fail "performance-optimization/SKILL.md contains unguarded RSpec-specific workflow wording"
  fi

  if rg -q 'RSpec' "$performance_n_plus_one" &&
    { ! rg -q 'Testing: rspec' "$performance_n_plus_one" ||
      ! rg -q 'Testing: minitest.*rails-testing' "$performance_n_plus_one"; }; then
    fail "performance-optimization/references/n-plus-one.md does not route Testing: minitest through rails-testing"
  fi

  if rg -qi 'axe-core specs' "$accessibility"; then
    fail "accessibility-review/SKILL.md contains unguarded axe-core specs wording"
  fi

  if ! rg -q 'Profile adaptation:.*rails-testing.*rails-css.*rails-frontend' "$accessibility_failures"; then
    fail "accessibility-review/references/common-failures.md lacks profile adaptation through rails-testing, rails-css, and rails-frontend"
  fi

  if ! rg -q 'Profile routing:.*rails-testing.*rails-css.*rails-frontend' "$accessibility_snippets"; then
    fail "accessibility-review/references/rails-snippets.md lacks profile routing through rails-testing, rails-css, and rails-frontend"
  fi
}

# Every skill must be reachable, or nothing can route an agent to it. Seeds are the entrypoints a
# user hits directly: the stable rails-* routers and every user-invocable skill. From there, follow
# skill names mentioned anywhere in a reached skill's directory -- body or references -- until the
# set stops growing. A skill outside that closure is dead payload: it costs description tokens in
# every session and no path leads to it.
#
# There is no exemption list by design. A skill meant to be reached only when the user asks for it
# by name declares `user-invocable: true`, which already makes it a seed.
check_reachability() {
  local all reached frontier skill missing

  all=$(find "$PACK/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

  reached=$(
    {
      printf '%s\n' "$all" |
        rg '^rails-(guide|architecture|models|testing|css|database|access|runtime|frontend|tenancy|deployment|workflow)$'
      while IFS= read -r skill; do
        if sed -n '2,/^---$/p' "$PACK/skills/$skill/SKILL.md" | rg -q '^user-invocable: *true'; then
          printf '%s\n' "$skill"
        fi
      done <<<"$all"
    } | sort -u
  )

  while :; do
    frontier=$(
      while IFS= read -r skill; do
        rg -oNI --no-messages -w -f <(printf '%s\n' "$all") "$PACK/skills/$skill" || true
      done <<<"$reached" | sort -u
    )
    frontier=$(printf '%s\n%s\n' "$reached" "$frontier" | sort -u)
    [ "$frontier" = "$reached" ] && break
    reached="$frontier"
  done

  missing=$(comm -23 <(printf '%s\n' "$all") <(printf '%s\n' "$reached"))
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    fail "unreachable skill: $skill is named by no router or reachable skill and is not user-invocable"
  done <<<"$missing"
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
check_profiled_review_guidance
check_reachability
check_links
check_host_validators

if [ "$failures" -gt 0 ]; then
  exit 1
fi

echo "Plugin verification passed"
