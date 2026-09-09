#!/usr/bin/env bash
# Verify the focused ChannelBay Rails Engineer payload and available Claude validator.
set -euo pipefail

cd "$(dirname "$0")/.."

PACK="rails-engineer"
CB_DOCS_ROOT="${CB_DOCS_ROOT:-$HOME/Projects/cb-dev-docs/docs}"
DOCS_PREFIX="~/Projects/cb-dev-docs/docs/"
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
    "$PACK/.codex-plugin/plugin.json"
}

check_marketplaces() {
  jq -e '
    (.plugins | length) == 1 and
    .plugins[0].name == "rails-engineer" and
    .plugins[0].source == "./rails-engineer"
  ' .claude-plugin/marketplace.json >/dev/null ||
    fail "Claude marketplace must expose only ./rails-engineer"

  jq -e '
    (.plugins | length) == 1 and
    .plugins[0].name == "rails-engineer" and
    .plugins[0].source.source == "local" and
    .plugins[0].source.path == "./rails-engineer"
  ' .agents/plugins/marketplace.json >/dev/null ||
    fail "Codex marketplace must expose only ./rails-engineer"
}

skill_description() {
  sed -n '2,/^---$/p' "$1" |
    awk '/^description:/ { found = 1 }
         found && !/^description:/ && /^[A-Za-z][A-Za-z0-9_-]*:/ { exit }
         found' |
    tr '\n' ' ' |
    sed -e 's/^description: *[>|]-* *//' -e 's/  */ /g' -e 's/ *$//'
}

check_skills() {
  local skill name description names count documented duplicates

  names=""
  while IFS= read -r skill; do
    name=$(sed -n '2,/^---$/p' "$skill" | sed -n 's/^name: *//p' | head -1)
    description=$(skill_description "$skill")

    [ -n "$name" ] || fail "$skill is missing frontmatter name"
    [ "$name" = "$(basename "$(dirname "$skill")")" ] ||
      fail "$skill directory/name mismatch: $name"
    [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] ||
      fail "$skill has invalid skill name: $name"
    [ -n "$description" ] || fail "$skill is missing frontmatter description"
    [[ "$description" == *"WHEN NOT:"* ]] ||
      fail "$skill description is missing a WHEN NOT boundary"
    # AGENTS.md is gitignored in the application checkout, so it resolves on an authoring machine
    # and nowhere else. A skill that cites it must say what to do when it is missing, or the agent
    # silently substitutes recalled constraints. Pinned verbatim so all skills state it identically.
    if rg -q 'AGENTS\.md' "$skill" &&
      ! rg -qF 'gitignored; if it is absent, say so and ask for it' "$skill"; then
      fail "$skill cites AGENTS.md without the absent-source clause"
    fi
    names+="$name"$'\n'
  done < <(find "$PACK/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

  count=$(printf '%s' "$names" | sed '/^$/d' | wc -l | tr -d ' ')
  [ "$count" -eq 9 ] || fail "expected 9 focused skills, found $count"
  documented=$(sed -n 's/.*ships \([0-9][0-9]*\) portable skills.*/\1/p' README.md)
  [ "$documented" = "$count" ] ||
    fail "README.md documents $documented skills but the payload contains $count"
  duplicates=$(printf '%s' "$names" | sed '/^$/d' | sort | uniq -d)
  [ -z "$duplicates" ] || fail "duplicate skill names: $duplicates"
}

check_routing() {
  local guide
  guide="$PACK/skills/rails-guide/SKILL.md"
  [ -f "$guide" ] || { fail "rails-guide is missing"; return; }
  rg -q '^user-invocable: true$' "$guide" || fail "rails-guide must be user-invocable"
  # The routing table lists skill names. Naming them is not routing; check_channel_bay_scope's
  # docs-prefix grep once passed on a sentence that promised a document and delivered this table.
  rg -qi 'invoke' "$guide" || fail "rails-guide must tell the agent to invoke the routed skill"

  for skill in 37signals-conventions channel-bay-backend channel-bay-frontend channel-bay-async \
    channel-bay-integrations channel-bay-operations channel-bay-testing channel-bay-review; do
    rg -q "$skill" "$guide" || fail "rails-guide must route to $skill"
  done
}

check_portability() {
  local matches
  matches=$(rg -n --glob SKILL.md '\$ARGUMENTS|\$\{CLAUDE_PLUGIN_ROOT\}|(^|[[:space:]])!\x60' "$PACK" || true)
  [ -z "$matches" ] || {
    echo "$matches" >&2
    fail "skill bodies contain a non-portable host-specific substitution"
  }
}

check_channel_bay_scope() {
  local old_payload
  rg -q 'ChannelBay' "$PACK/skills/rails-guide/SKILL.md" ||
    fail "rails-guide must identify ChannelBay scope"
  rg -q '~/Projects/cb-dev-docs/docs/' "$PACK/skills/rails-guide/SKILL.md" ||
    fail "rails-guide must point to companion documentation"

  old_payload=$(find "$PACK" -maxdepth 1 -type f \( -name plugin.json -o -name AGENTS_TEMPLATE.md \) -print)
  [ -z "$old_payload" ] || fail "retired host/profile payload remains: $old_payload"
  [ -z "$(find "$PACK/specify" -type f -print 2>/dev/null)" ] || fail "retired SDD payload remains"
  [ -z "$(find "$PACK/docs/37signals-playbook" -type f -print 2>/dev/null)" ] ||
    fail "retired generic playbook remains"
  [ ! -f scripts/sync_skills_to_agents_dir.sh ] || fail "retired opencode mirror script remains"
}

check_links() {
  local file link target
  while IFS= read -r file; do
    while IFS= read -r link; do
      link=$(sed 's/^](//;s/)$//' <<<"$link")
      case "$link" in
        http*|/*|\#*) continue ;;
      esac
      target="$(dirname "$file")/$(sed 's/#.*//' <<<"$link")"
      [ -e "$target" ] || fail "broken Markdown link: $file -> $link"
    done < <(rg -o '\]\([^)]+\.md[^)]*\)' "$file" || true)
  done < <(find . -path ./.git -prune -o -type f -name '*.md' -print)
}

# Skill bodies point at documentation as bare prose paths, which check_links cannot see.
# Two contracts are enforced here:
#   1. A companion-doc path carries the full ~/Projects/cb-dev-docs/docs/ prefix. Bare
#      reference/x.md is one character from skill-local references/x.md and reads as either.
#   2. Every path resolves — skill-local first, then the companion docs root.
check_doc_paths() {
  local skill line path rel

  while IFS= read -r skill; do
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      fail "companion-doc path is missing the $DOCS_PREFIX prefix: $skill -> $line"
    done < <(sed "s|~/Projects/cb-dev-docs/docs/[A-Za-z0-9._/-]*||g" "$skill" |
      grep -oE '(^|[^/A-Za-z-])(architecture|guides|reference|modules|view-components|frontend|getting-started)/[a-z0-9-]+\.md' |
      sed 's/^[^A-Za-z]*//' | sort -u)
  done < <(find "$PACK/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)

  if [ ! -d "$CB_DOCS_ROOT" ]; then
    echo "SKIP: companion docs absent at $CB_DOCS_ROOT; doc-path resolution not checked"
    return
  fi

  while IFS= read -r skill; do
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      rel="${path#\~/Projects/cb-dev-docs/docs/}"
      [ -e "$(dirname "$skill")/$rel" ] || [ -e "$CB_DOCS_ROOT/$rel" ] ||
        fail "doc path resolves neither skill-locally nor under $CB_DOCS_ROOT: $skill -> $path"
    done < <(grep -oE '(~/Projects/cb-dev-docs/docs/|references/)[A-Za-z0-9._/-]*\.md' "$skill" | sort -u)
  done < <(find "$PACK/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | sort)
}

check_host_validator() {
  if [ "${RAILS_ENGINEER_SKIP_HOST_VALIDATORS:-}" = "1" ]; then
    echo "SKIP: host validation disabled for payload contract test"
    return
  fi

  if command -v claude >/dev/null 2>&1; then
    claude plugin validate --strict "./$PACK"
  else
    echo "SKIP: Claude Code is not installed"
  fi
}

check_json
check_marketplaces
scripts/check_versions.sh
check_skills
check_routing
check_portability
check_channel_bay_scope
check_links
check_doc_paths
check_host_validator

if [ "$failures" -gt 0 ]; then
  exit 1
fi

echo "Plugin verification passed"
