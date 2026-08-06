# Repository Configuration

This repository is a plugin marketplace for Claude Code, OpenAI Codex, Google Antigravity, and opencode. It ships one profile-aware Rails pack, not a Rails application: there is no `app/`, Gemfile, or Ruby test suite. Content is Markdown, JSON, and small Bash utilities.

## What ships

| Path | Contents |
|---|---|
| `.claude-plugin/marketplace.json` | Claude Code marketplace manifest for `rails-engineer` |
| `.agents/plugins/marketplace.json` | Codex marketplace manifest for `rails-engineer` |
| `rails-engineer/` | One profile-aware pack: portable skills, static references, 37signals playbook, Spec-Kit seed, and three host manifests |
| `rails-engineer/.claude-plugin/plugin.json` | Claude Code plugin manifest |
| `rails-engineer/.codex-plugin/plugin.json` | Codex plugin manifest |
| `rails-engineer/plugin.json` | Antigravity plugin manifest; it must live at the pack root |

The pack ships no agents, commands, hooks, generated bridge trees, or MCP server. Workflows are user-invocable skills, and onboarding happens after installation through `rails-onboard` in the target Rails application. The two guidance families are selected by the marked Rails Engineer Profile in that application's `AGENTS.md`; never infer a migration from changing profile choices.

## Portability

**Skills are the single portable payload.** `rails-engineer/skills/` is the canonical copy. Add a new host through a small manifest, or no manifest when its native discovery already reads the skill tree; never add a generated mirror for an individual host.

Three rules apply to every skill body:

1. Do not use `` !`cmd` `` load-time execution. It is Claude-Code-only, inert elsewhere, and a non-zero exit aborts skill loading on Claude.
2. Do not use bare `${CLAUDE_PLUGIN_ROOT}`. Claude substitutes it in skill bodies but other hosts leave it empty. When a skill needs its own path, set `SKILL_DIR="<absolute path loaded for this skill>";` inside the same Bash call. The trailing semicolon matters because some hosts flatten fenced blocks. `${CLAUDE_PLUGIN_ROOT}` remains valid only in a manifest or Claude hook configuration; this pack ships neither hooks nor MCP.
3. Do not use `$ARGUMENTS`. Retain `argument-hint:` frontmatter when useful and refer to the user's request in prose instead.

| Surface | Claude Code | Codex | Antigravity | opencode |
|---|---|---|---|---|
| Skills | yes | yes — namespaced as `rails-engineer:<skill>` | yes | yes — canonical path or workspace `.agents/skills/` mirror |
| User-invocable workflows | `/rails-onboard` and other supported skills | ask for the skill by name | invoke as a skill | ask for the skill by name; `user-invocable` frontmatter is ignored |
| Commands, agents, hooks | not shipped | not shipped | not shipped | not shipped |
| MCP servers | none shipped | none shipped | none shipped | none shipped; configuration is user-owned |

Codex and Antigravity snapshot the whole pack on installation, so relative references inside it are available. opencode installs nothing: it can read `rails-engineer/skills` from its `skills` array or the workspace `.agents/skills/<name>/SKILL.md` mirror. Restart opencode after changing an external source or upgrading it.

## Dogfooding

Claude Code reads the marketplace tree:

```bash
/plugin marketplace add ./
/plugin install rails-engineer@rails-engineer
```

Installed Claude marketplaces are git clones under `~/.claude/plugins/marketplaces/`; run `/plugin marketplace update rails-engineer` after editing this repository.

Codex uses the same tree but snapshots it into a version-pinned cache:

```bash
codex plugin marketplace add ./
codex plugin add rails-engineer@rails-engineer
```

Bump the Codex manifest version before reinstalling; never hard-code its cache path.

Antigravity installs the pack directory into the global shared plugin location:

```bash
agy plugin install ./rails-engineer
agy plugin validate ./rails-engineer
```

From a clone, the lighter workspace-only route is:

```bash
scripts/sync_skills_to_agents_dir.sh
opencode debug skill > /tmp/rails-engineer-opencode-skills.json
jq --arg d "$PWD/.agents/skills/" '[.[] | select(.location | startswith($d))] | length' /tmp/rails-engineer-opencode-skills.json
```

The mirror contains symlinks and is gitignored. It is intentionally only for this clone, because host discovery stops at the git worktree root.

## Adding content

- **Skill** — `rails-engineer/skills/<name>/SKILL.md`. Directory and frontmatter `name:` must match. Write a `description:` with a clear WHEN + WHEN NOT boundary; vague descriptions do not trigger reliably.
- **Profile-aware guidance** — a public router must read the target application's `AGENTS.md` profile before naming a detailed variant. Keep layered and rich-model examples in their own distinctly named variant skills; do not allow same-name collisions.
- **Workflow** — a user-invocable skill, not a command. Keep an SDD workflow behind the `Workflow: sdd` profile choice, and offer conventional work when it is not selected.
- **Convention reference** — place it under the appropriate conventions skill's `references/` directory. Preserve `paths:` frontmatter so users can copy it into `.claude/rules/` for deterministic path-triggered loading.
- **Profile restrictions** — a rule that bans a third-party stack must defer to the target application's recorded deliberate divergences. Existing applications may have valid reasons to retain an established dependency.

Links inside the pack are resolved relative to the containing file and fail silently in hosts. After moving content, run the release gate in [Verification](#verification).

## Releasing

The version must agree in four places:

1. `.claude-plugin/marketplace.json` → `metadata.version`
2. `.claude-plugin/marketplace.json` → `plugins[0].version`
3. `rails-engineer/.claude-plugin/plugin.json` → `version`
4. `rails-engineer/.codex-plugin/plugin.json` → `version`

Run `scripts/check_versions.sh` before tagging `v<version>`. The Codex manifest version is load-bearing because its cache key includes it. The Antigravity manifest has no version field, and opencode has no manifest.

## Scripts

| Script | Purpose |
|---|---|
| `sync_skills_to_agents_dir.sh` | Rebuild the workspace `.agents/skills/` symlink mirror from the single pack |
| `check_versions.sh` | Assert the version string agrees across every versioned manifest |
| `verify_plugins.sh` | Release gate: marketplace wiring, manifests, versions, skill metadata, portability, links, and installed host validators |

## Verification

Run the full local release gate:

```bash
scripts/verify_plugins.sh
bash test/render_profile_test.sh
bash test/plugin_payload_test.sh
```

The verification script resolves every relative Markdown link in the repository, checks the single-pack marketplace contract and uniqueness of skill names, then runs available Claude and Antigravity validators. CI repeats those checks and performs isolated installation/discovery smoke tests against the latest supported host CLIs.
