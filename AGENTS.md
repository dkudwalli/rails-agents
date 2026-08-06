# Repository Configuration

This repository is a **plugin marketplace** for Claude Code, OpenAI Codex, Google Antigravity and
opencode, not a Rails application. There is no `app/` directory, no Gemfile, and no test suite. The
content is Markdown, JSON, and a little Bash and Python.

## What ships

| Path | Contents |
|------|----------|
| `.claude-plugin/marketplace.json` | Claude Code marketplace manifest listing both plugins |
| `.agents/plugins/marketplace.json` | Codex marketplace manifest listing both plugins |
| `rails-layered/` | Plugin: layered Rails 8 architecture (agents, commands, skills, hooks, Spec-Kit seed) |
| `rails-37signals/` | Plugin: vanilla Rails per the 37signals playbook (agents, skills, hooks, vendored playbook) |
| `rails-37signals/PROFILE_TEMPLATE.md` | Copyable application-profile template; users copy it to their own `CLAUDE.md` before applying the pack |
| `rails-<pack>/.claude-plugin/plugin.json` | Claude Code plugin manifest |
| `rails-<pack>/.codex-plugin/plugin.json` | Codex plugin manifest |
| `rails-<pack>/plugin.json` | Antigravity plugin manifest — it only reads a manifest at the plugin root, so this one cannot live in a dotted subdirectory like the other two |
| — | **opencode needs no manifest.** It has no plugin or marketplace format for content; it discovers skills from paths it already reads. Each pack root therefore still carries exactly three manifests |

**This repo ships no MCP server.** It used to declare Sentry's hosted server in
`rails-layered/.mcp.json` and `rails-layered/mcp_config.json`; both are gone along with the
`sentry-*` skills. The § Portability notes on MCP are kept because they are the researched answer
for the next server anyone tries to ship, not because anything currently depends on them.

The two plugins are **mutually exclusive by design**. They disagree on database, test framework,
authorization, CSS strategy, and whether a service layer exists. Never merge content between them,
and never add a rule to one that assumes the other's stack.

## Portability

**Skills are the single portable payload.** `rails-<pack>/skills/` is the one canonical copy; each
tool's manifest points at it. Adding a tool should mean one small manifest — or, as with opencode,
none at all — never a mirror.

Three rules follow, and each already had a hit in this repo:

1. **No `` !`cmd` `` load-time execution in skill bodies.** Claude-Code-only — inert literal text
   everywhere else, and a non-zero exit aborts skill load on Claude.
2. **No bare `${CLAUDE_PLUGIN_ROOT}` in skill or command bodies.** It is a Claude Code SKILL.md
   substitution that expands to empty on every other host, so a guarded branch silently never fires.
   Have the agent set `SKILL_DIR="<the absolute path it loaded the skill from>";` inline in the same
   Bash call instead — keep the trailing `;`, some hosts flatten fenced blocks to one line.
   `${CLAUDE_PLUGIN_ROOT}` inside `.mcp.json` and `hooks.json` is fine; Codex provides it there.
   That carve-out stops at `mcp_config.json` — Antigravity has no plugin-root variable of any name,
   so a server whose command needs its own path cannot ship for it at all. opencode has none either,
   and its config interpolation is `{env:VAR}` / `{file:path}` — shell-style `${VAR}` is not
   substituted at all. The repo ships no MCP server today, so nothing depends on this; ship a remote
   server rather than a command-with-a-path one and it stays that way.
3. **No `$ARGUMENTS` in skill bodies.** Keep `argument-hint:` frontmatter — portable, and ignored
   where unsupported — and refer to the user's request in prose.

What each tool can and cannot take:

| Surface | Claude Code | Codex | Antigravity | opencode |
|---|---|---|---|---|
| Skills | yes | yes — plugin `skills/`, namespaced in-session as `rails-layered:<skill>` | yes — plugin `skills/`, same `<name>/SKILL.md` layout, no manifest key needed | yes — no install at all. It reads `.agents/skills/<name>/SKILL.md` from the workspace (walking up to the git worktree root), so `scripts/sync_skills_to_agents_dir.sh` output is already a complete install. Elsewhere, add `rails-<pack>/skills` to the `skills` array in `opencode.json` |
| MCP servers | **none shipped.** Would be `.mcp.json` + a `"type": "http"` + `"url"` pair | **none shipped.** Would be `"mcpServers": "./.mcp.json"` in `.codex-plugin/plugin.json` | **none shipped.** Would be `mcp_config.json` at the plugin root, where a remote server is `serverUrl`, not `"type": "http"` + `"url"` | **not shippable at all.** MCP lives in the user's `opencode.json`, and a remote server is a *third* spelling: `{"type": "remote", "url": …}` with `type` required |
| Slash commands | yes | **no.** Codex prompts live in `$CODEX_HOME/prompts/` only, are not repo-shareable, and are deprecated in favour of skills | ingested — `agy plugin install` reports `commands: converted to skills`, but it counted 3 for `rails-layered`'s 19 nested files, so assume only top-level ones survive. Every workflow already exists as a skill, so nothing depends on this | supported as `.opencode/command/<name>.md` — flat, filename is the command name — but **not shipped**; `commands/` here is nested, and every workflow already exists as a skill |
| Agents | yes | **no.** Codex subagents are TOML in `.codex/agents/`; a plugin manifest has no `agents` key | ingested — `agents: 19 processed`. Verified as accepted at install, not as behaving like Claude subagents | supported as `.opencode/agent/<name>.md`, but a different frontmatter vocabulary (`mode`, `permission`, and unknown keys silently absorbed into `options`). **Not shipped** — see below |
| Hooks | yes | **no.** `plugin_hooks` is a *removed* feature flag as of CLI 0.146.0; users copy `hooks/hooks.json` into their own `.codex/hooks.json` | **not shipped** — see below | **not shipped** — see below |
| Rules | n/a | n/a | supported (`rules/`), **not shipped** — see below | reads `AGENTS.md`, falling back to `CLAUDE.md`, so the profile template works unchanged. An `instructions[]` config key takes globs and could load the conventions references path-scoped, but its documented examples are project-relative and this repo has not exercised it |

Codex copies the **entire** plugin root on install, not just the declared paths, so anything a skill
references by relative path is present in the cache. So does Antigravity: `agy plugin install`
copies the pack into `~/.gemini/config/plugins/<name>/`, dotted manifest directories and all. Each
pack root therefore carries three manifests, one per host — none of them is cruft. opencode adds no
fourth: it installs nothing and reads the skill directories in place.

opencode ignores unrecognised skill frontmatter, so `user-invocable: true` is dropped — its agents
load skills through a native `skill` tool rather than as `/<name>`. Restart after changing an
explicit external skill source or upgrading opencode.

### Why Antigravity gets no `hooks.json` or `rules/`

**Hooks.** The schema is not a rename away. Antigravity keys the file by hook *name* at the top
level rather than under `{"hooks": {…}}`, matches on its own tool names (`run_command`,
`browser_.*`) instead of `Edit|Write|Bash`, and expects `PreToolUse` to refuse by writing
`{"decision": "deny"}` to stdout rather than exiting 2. Copying `hooks/hooks.json` produces a file
that loads and never fires. A translation would be a third divergent copy of the same four hooks.

**Rules.** `rules/*.md` is a real plugin component and the conventions references are the obvious
candidates, but they already reach Antigravity inside the conventions skill, and a bridge means a
third generated tree to keep in step. If it is ever wanted: confirm the frontmatter keys against
`agy` first — `always_on`, `model_decision` and glob triggers exist, the exact YAML spelling is
unverified — then transform each reference's `paths:` frontmatter into whatever glob key `agy`
expects.

**The standing rule against generated bridge trees.** GitHub Copilot — supported until v1.2.0, then
dropped — once had one: a prefixed copy of every convention reference, regenerated by a script. It
was deleted as unused duplication, and then so was the host. Do not recreate that pattern for any
tool without a consumer asking for it. Content reaches a new host through the canonical `skills/`
directory or it does not reach it.

### Why opencode gets no hooks, agents, or commands

**Hooks.** opencode has no hooks file at all. Hooks exist only *as* plugins: JavaScript or
TypeScript modules in `.opencode/plugin/` (or an npm package named in `plugin[]`) exporting a
function that returns handlers keyed on opencode's own events — `tool.execute.before`,
`file.edited`, `permission.ask`. There is no exit-code protocol; a `PreToolUse` refusal becomes
mutating `output.status` to `"deny"` inside `permission.ask`. Translating `hooks/hooks.json` means
shipping JavaScript and maintaining a fourth divergent copy of the same four hooks.

**Agents and commands.** Both are supported surfaces, and a JS/TS plugin *can* inject them — its
`config` hook receives the live merged config, so `cfg.skills.paths.push(join(import.meta.dir, …))`
makes bundled content visible. That is still a JavaScript payload plus a second copy of every agent
in opencode's frontmatter vocabulary. The skills already carry the same material to opencode, so
the bridge buys nothing.

## What does not ship

| Path | Why it stays at repo root |
|------|---------------------------|
| `.claude/` | This repo's own config: settings, plus the two agent-behaviour rules (`caveman`, `cli-tools`) |
| | These two describe how the *assistant* should work, not how Rails code should be written, so they are deliberately withheld from both plugins. `cli.md` (Rails commands) does ship — it is pack content. If you add a rule, decide which of those two categories it is in before choosing where it lives |
| `docs/` | One repo-specific guide: `your-first-sdd-feature.md`, an onboarding walkthrough for the SDD kit. No plugin consumes it. Guides that merely restate Anthropic's own documentation keep getting deleted — prompt engineering and MCP setup both went this way — so link the official docs instead of re-hosting them |
| `scripts/` | Maintenance tooling: rebuilds the skill mirror, checks manifest version drift |
| `.agents/skills/` | Generated, gitignored skill mirror for **one** pack — symlinks, never copies. Rebuild with `scripts/sync_skills_to_agents_dir.sh <layered\|37signals>`. Plugin installs do not use it. Antigravity and opencode both read `{workspace}/.agents/skills/<name>/SKILL.md` directly, so once the script has been run the mirror *is* a workspace-scoped install of the selected pack — but it is gitignored, so a fresh clone has nothing until someone runs it. It only reaches a *clone of this repo*: the script always writes into the rails-engineer checkout, and both tools stop walking up at the git worktree root |
| `.agents/plugins/` | Shared namespace. Codex takes `marketplace.json` from it; Antigravity ignores that file and scans the directory for *subdirectories* containing a `plugin.json`. Nothing installs a pack there, so today only Codex reads anything from it |

## Dogfooding

This repo installs its own marketplace, so the shipped artifact is the one being authored:

```bash
/plugin marketplace add ./
/plugin install rails-layered@rails-engineer
```

Installed marketplaces are git clones under `~/.claude/plugins/marketplaces/`, so after editing
plugin content run `/plugin marketplace update rails-engineer` before the installed copy reflects
the change.

Codex reads the same tree:

```bash
codex plugin marketplace add ./
codex plugin add rails-layered@rails-engineer
```

Codex snapshots into a **version-pinned** cache at
`~/.codex/plugins/cache/rails-engineer/<plugin>/<version>/`, so editing plugin content is not enough
— bump `version` in the `.codex-plugin/plugin.json` and re-run `codex plugin add` to pick the change
up. Never hard-code a path into that cache; it moves on every release.

Antigravity has no marketplace; `agy plugin install` takes a directory:

```bash
agy plugin install ./rails-layered      # then: agy plugin list
agy plugin validate ./rails-layered     # component counts, no install
```

It copies into `~/.gemini/config/plugins/<plugin>/` — the *global* location, shared with the IDE,
and a snapshot rather than a link. Editing plugin content means re-running `install`. The path is
not version-keyed, so unlike Codex there is no version to bump; the Antigravity manifest carries no
`version` field at all, which is why § Releasing still lists six places and `check_versions.sh` is
unchanged. Working from a clone, `scripts/sync_skills_to_agents_dir.sh` is the lighter option: it
gives Antigravity the same skills through `.agents/skills/` with nothing installed.

opencode installs nothing at all. Inside a clone it picks up `.agents/skills/` as soon as the mirror
script has run; anywhere else, add the pack path to the `skills` array:

```bash
scripts/sync_skills_to_agents_dir.sh layered
opencode debug skill > /tmp/oc.json   # never pipe to head — SIGPIPE truncates the scan
jq --arg d "$PWD/.agents/skills/" '[.[] | select(.location | startswith($d))] | length' /tmp/oc.json
```

Restart opencode after changing the external skill source or upgrading it.

## Adding content

- **Skill** — `rails-<pack>/skills/<name>/SKILL.md`. The directory name must equal the frontmatter
  `name:`. Write the `description:` with the WHEN + WHEN NOT pattern the existing skills use;
  a vague description means the skill never triggers. In `rails-layered`, three skills divide the
  same subject matter and must not re-absorb each other: `rails-architecture` decides *which layer*
  and carries no worked implementations, `layered-conventions` states the *rule* for a layer in a
  path-scoped reference, and `<layer>-patterns` holds the *code*. Put a Ruby example in the pattern
  skill and link to it; the moment `rails-architecture/references/` grows an implementation again it
  has contradicted its own `WHEN NOT`.
- **Agent** — `rails-<pack>/agents/<name>.md`. Bare agent names resolve from inside a plugin, so
  commands can dispatch to them unqualified. **Keep agents thin.** An agent body is a persona plus a
  router; reference material belongs in a skill, because `agents/` reaches Claude Code only. There is
  no longer an `agents/references/` directory — every topic that lived there is a skill, and the
  agents link into `../skills/<name>/references/` and declare the skill in `skills:`.
- **Workflow** — a skill, not a command: `rails-layered/skills/<name>/SKILL.md` with
  `user-invocable: true`. Skills reach every host; commands reach Claude Code only. `commands/`
  now holds nothing but shims that read a skill, kept so the `/sdd:*` and `/sdd-change:*` namespaces
  and their `handoffs` chains survive — `handoffs` has no skill equivalent. Write a new command only
  when it cannot work without a Claude Code feature, and say which feature in the file.
- **Convention rule** — `rails-<pack>/skills/<pack>-conventions/references/<name>.md`, keeping the
  `paths:` frontmatter. It is parsed two ways: as skill reference content, and as a drop-in Claude
  Code rule when a user copies it into their own `.claude/rules/`.

**A `Never:` rule that names a third-party stack needs a profile escape hatch.** `rails-37signals`
forbids Tailwind, RSpec, Devise, Sidekiq, Elasticsearch, bundlers, `app/services` and policy layers
— correct for a new application, wrong as a refusal on a brownfield app that already runs one. Each
such skill carries a `- **Profile override:**` bullet immediately above its `Never:` line deferring
to the **Deliberate divergences** block in the target app's `CLAUDE.md`, and the three conventions
references that repeat the prohibition (`css.md`, `testing.md`, `views.md`) carry the same note as a
blockquote, because a copy in `.claude/rules/` never sees the parent skill. Add one to any new skill
that bans a stack rather than a shape. `rails-layered` needs none of this — it prescribes patterns,
not a forbidden-dependency list.

Links inside plugins are resolved relative to the containing file, and nothing fails loudly when one
breaks. After any move, run the link resolver in § Verification below.

## Releasing

The version string lives in **six** places:

1. `.claude-plugin/marketplace.json` → `metadata.version`
2. `.claude-plugin/marketplace.json` → each `plugins[].version`
3. `rails-layered/.claude-plugin/plugin.json` → `version`
4. `rails-37signals/.claude-plugin/plugin.json` → `version`
5. `rails-layered/.codex-plugin/plugin.json` → `version`
6. `rails-37signals/.codex-plugin/plugin.json` → `version`

`scripts/check_versions.sh` fails if they disagree — run it before tagging `v<version>`. The Codex
manifests are load-bearing here beyond bookkeeping: the plugin cache is keyed by version, so a stale
one means users never receive the update. Antigravity's `rails-<pack>/plugin.json` carries no
`version` field, and opencode has no manifest to carry one, so neither adds a seventh place.

## Rebuilding the skill mirror

```bash
scripts/sync_skills_to_agents_dir.sh layered      # or 37signals
```

`.agents/skills/` mirrors **one** pack, unprefixed, so each directory name equals its frontmatter
`name:` exactly as in the pack. It must not carry both: seven skills — `job-patterns`, `legacy-migration`,
`migration-patterns`, `mailer-patterns`, `model-patterns`, `stimulus-patterns`, `turbo-patterns` — now
exist in both packs with deliberately opposite advice, and skill discovery resolves on the frontmatter
`name:`, so mirroring both would make those seven ambiguous. Entries are symlinks, so they track edits
automatically and a new skill needs no manual step — just re-run the script when you add or remove
one. Both Antigravity and opencode read the result, so switching packs switches what either tool
sees in this workspace.

## Scripts

| Script | Purpose |
|---|---|
| `sync_skills_to_agents_dir.sh` | Rebuild the `.agents/skills/` symlink mirror for one pack. Takes `layered` or `37signals` |
| `check_versions.sh` | Assert the version string agrees across every manifest that carries one. Run before tagging |
| `verify_plugins.sh` | Release gate: manifests, versions, skill metadata, portability rules, links, and installed host validators |

## Verification

After any move or rename, resolve every relative Markdown link. The root `README.md` and this file
are in scope too, so keep `.` in the find list:

```bash
find . -path ./.git -prune -o -type f -name '*.md' -print | while IFS= read -r f; do
  grep -oE '\]\([^)]+\.md[^)]*\)' "$f" | sed 's/^](//;s/)$//' | while IFS= read -r link; do
    case "$link" in http*|/*|\#*) continue ;; esac
    [ -e "$(dirname "$f")/${link%%#*}" ] || echo "BROKEN $f -> $link"
  done
done
```

Manifests and hook files must parse, and the version must agree everywhere `check_versions.sh`
looks (the Antigravity manifests carry no version and are excluded by design):

```bash
jq empty .claude-plugin/marketplace.json rails-*/.claude-plugin/plugin.json \
         rails-*/.codex-plugin/plugin.json rails-*/plugin.json \
         rails-*/hooks/hooks.json rails-layered/specify/init-options.json
scripts/check_versions.sh
```

Component counts must match what the READMEs claim:

```bash
agy plugin validate ./rails-layered      # expect: skills 54, agents 18
agy plugin validate ./rails-37signals    # expect: skills 24, agents 3
```

`agy` reports what it ingested without installing. The `opencode debug skill` count in § Dogfooding
is the equivalent check for the mirror — anchor its filter on `$PWD`, because a bare
`contains(".agents/skills")` also matches any global `~/.agents/skills/` you happen to have and
quietly inflates the count.

Run the complete local gate with `scripts/verify_plugins.sh`. CI repeats it on every pull request
and weekly against the latest host CLIs, then performs isolated install/discovery smoke tests.
