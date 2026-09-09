# Repository Configuration

This repository publishes the ChannelBay-only Rails Engineer plugin. It is Markdown, JSON, and Bash
release tooling, not a Rails application. The supported hosts are Claude Code and OpenAI Codex.

## Payload

| Path | Contents |
|---|---|
| .claude-plugin/marketplace.json | Claude Code marketplace manifest |
| .agents/plugins/marketplace.json | Codex marketplace manifest |
| rails-engineer/ | Canonical portable skill payload |
| rails-engineer/.claude-plugin/plugin.json | Claude plugin manifest |
| rails-engineer/.codex-plugin/plugin.json | Codex plugin manifest |
| rails-engineer/evals/ | Routing eval cases for `claude plugin eval` |

The package remains named rails-engineer for marketplace continuity, but its content applies only to
ChannelBay. It ships nine skills: rails-guide, 37signals-conventions, plus ChannelBay backend,
frontend, async, integrations, operations, testing, and review playbooks.

## Source of truth

The ChannelBay checkout at ~/Projects/channel_bay supplies current constraints in AGENTS.md. The
companion documentation at ~/Projects/cb-dev-docs/docs/ is the detailed reference. Skills must point
there rather than copy volatile runbooks. Do not turn recorded application divergences into migration
advice.

## Skill authoring

- Skills live at rails-engineer/skills/name/SKILL.md. The directory and frontmatter name must match.
- Keep descriptions concise, name the ChannelBay task boundary with WHEN NOT, and route every
  non-user-invocable skill from rails-guide. rails-guide must tell the agent to *invoke* the routed
  skill; naming it is not routing.
- Any skill citing AGENTS.md must carry the absent-source clause verbatim. The application checkout
  gitignores its AGENTS.md, so the file resolves only where someone authored it, and a skill that
  cites it without saying what to do when it is missing invites the agent to substitute recalled
  constraints. verify_plugins.sh pins one literal; do not reword it per skill.
- Where a skill and the checkout's own numbered docs/ disagree, ~/Projects/cb-dev-docs/docs/ is the
  current copy. Do not add pointers into the mirror.
- Do not use load-time commands, CLAUDE_PLUGIN_ROOT substitution, or ARGUMENTS in skill bodies.
- 37signals-style rich models and resourceful CRUD are the default for new local domain behavior and
  incremental modernization. Preserve ChannelBay platform choices; do not treat its service-heavy
  history as a required architecture.
- Do not add alternative Rails stacks, profile selection, onboarding, SDD workflows, Antigravity, or
  opencode support. Those are deliberately out of scope.
- References inside a skill must resolve from the ChannelBay checkout or companion documentation, not
  to a copied generic handbook.

## Releasing

The version must agree in four locations:

1. .claude-plugin/marketplace.json metadata.version
2. .claude-plugin/marketplace.json plugins[0].version
3. rails-engineer/.claude-plugin/plugin.json version
4. rails-engineer/.codex-plugin/plugin.json version

Codex cache identity includes its manifest version. Bump all four before reinstalling a release.
Run scripts/release_check.sh from a clean worktree before tagging the printed version.

## Verification

scripts/check_versions.sh checks manifest agreement. scripts/verify_plugins.sh validates the
Claude/Codex marketplace, skill metadata and routing, portability, links, ChannelBay-specific
content, and the available Claude validator. scripts/release_check.sh runs them with the payload and
release-contract tests.

Those gates check structure and that every referenced document resolves; they cannot check whether
the descriptions route correctly. That is what rails-engineer/evals/ is for:

    claude plugin eval ./rails-engineer --ablation with-without --threshold 0.8

Run it manually before a release that touches any description or rails-guide's routing table. It is
not in release_check.sh or CI: the cases cost model calls, and `claude plugin eval` is currently
gated behind early access, so it is unavailable on some accounts.
