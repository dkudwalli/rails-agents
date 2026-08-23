# Rails Engineer

Rails Engineer is one profile-aware plugin marketplace for Ruby on Rails development. It works with Claude Code, OpenAI Codex, Google Antigravity, and opencode. Install it once, then have its `rails-onboard` skill record the conventions your application actually uses before applying any guidance.

The pack carries both coherent guidance families:

| Profile | Guidance selected after onboarding |
|---|---|
| **Layered** | Services, queries, forms, policies, presenters, RSpec, Pundit, ViewComponent, Tailwind, PostgreSQL, and the optional SDD workflow |
| **Rich models** | Rich Active Record models, namespaced concerns, state records, CRUD controllers, Minitest + fixtures, plain CSS, and the conditional 37signals playbook |

The profile is an explicit application decision, not a migration command. Existing applications are observed and confirmed; mixed choices are allowed when recorded as deliberate divergences.

## Quick start

Install Rails Engineer, then work from the target Rails application:

| Host | Install | First prompt |
|---|---|---|
| Claude Code | `/plugin marketplace add dkudwalli/rails-agents` then `/plugin install rails-engineer@rails-engineer` | Run `/rails-onboard`, then `/rails-guide` for your first task. |
| OpenAI Codex | `codex plugin marketplace add dkudwalli/rails-agents` then `codex plugin add rails-engineer@rails-engineer` | “Use `rails-engineer:rails-onboard` for this application,” then “Use `rails-engineer:rails-guide` for this task.” |
| Google Antigravity | `git clone https://github.com/dkudwalli/rails-agents` then `agy plugin install ./rails-agents/rails-engineer` | Ask the assistant to use `rails-onboard`, then `rails-guide`. |
| opencode | Add `rails-engineer/skills` with the stable 1.x `skills.paths` configuration shown below. | Ask the assistant to use `rails-onboard`, then `rails-guide`. |

Onboarding proposes an editable complete profile from repository evidence for existing apps, or from one of three new-app starting stacks: Layered, Rich Models — Fizzy-style, or Rich Models — ONCE-compatible. It writes the resulting section to `AGENTS.md` only after preview and explicit confirmation.

To reconfigure later, run onboarding again. It replaces only that marked section and preserves all other `AGENTS.md` content. See the pack's [first-10-minutes guide](rails-engineer/README.md#first-10-minutes) and [profile template](rails-engineer/AGENTS_TEMPLATE.md).

## What you get

Rails Engineer ships 92 portable skills, static references, and an optional Spec-Kit seed. It does not ship agents, slash-command shims, hooks, or MCP servers: skills are the portable payload on every supported host.

Start work through `rails-guide` when the entrypoint is unclear. It checks that onboarding is complete and selects the right stable profile-aware router: `rails-architecture`, `rails-models`, `rails-testing`, `rails-css`, `rails-database`, `rails-access`, `rails-runtime`, `rails-frontend`, `rails-tenancy`, `rails-deployment`, or `rails-workflow`. `rails-architecture` now selects an explicit architecture guide for either layered or rich-models applications; every router then selects the matching detailed skill or convention reference.

The Spec Driven Development skills are available only when onboarding selects `Workflow: sdd`. They remain opt-in and never install project files automatically. Run `sdd-init` once before the first `sdd-specify`; [Your First SDD Feature](docs/your-first-sdd-feature.md) walks through the workflow.

### Conventions

Claude Code auto-loads rules only from a project's own `.claude/rules/`; a plugin cannot make rules path-triggered automatically. The `layered-conventions` and `37signals-conventions` skills route to the profile-appropriate references when invoked. If you want deterministic path-triggered rules, copy the references for the profile your `AGENTS.md` selects:

```bash
mkdir -p .claude/rules
cp <installed-rails-engineer>/skills/layered-conventions/references/*.md .claude/rules/
# or, for a rich-models application:
cp <installed-rails-engineer>/skills/37signals-conventions/references/*.md .claude/rules/
```

## Other coding agents

**OpenAI Codex** uses the same marketplace:

```bash
codex plugin marketplace add dkudwalli/rails-agents
codex plugin add rails-engineer@rails-engineer
```

Skills appear namespaced as `rails-engineer:<skill>`.

**Google Antigravity** has no marketplace; install the pack directory:

```bash
git clone https://github.com/dkudwalli/rails-agents
agy plugin install ./rails-agents/rails-engineer
```

It copies the pack into `~/.gemini/config/plugins/`, so rerun the install after upgrading.

**opencode** needs no plugin install. In stable 1.x, point `skills.paths` at the canonical tree:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": {
    "paths": ["~/src/rails-agents/rails-engineer/skills"]
  }
}
```

The v2 `skills` array syntax is preview-only:

```jsonc
{
  "skills": ["~/src/rails-agents/rails-engineer/skills"]
}
```

Alternatively, inside a clone run `scripts/sync_skills_to_agents_dir.sh`. The workspace `.agents/skills/` mirror is version-neutral, so it avoids choosing either configuration shape. Restart opencode after changing an external skill source or upgrading it.

## Documentation

| Document | Purpose |
|---|---|
| [Rails Engineer pack guide](rails-engineer/README.md) | Onboarding, profile routing, and workflow availability |
| [37signals Rails Playbook](rails-engineer/docs/37signals-playbook/PLAYBOOK.md) | Conditional rich-model reference extracted from `fizzy`, `once-campfire`, and `writebook` |
| [Your First SDD Feature](docs/your-first-sdd-feature.md) | Step-by-step onboarding walkthrough for the optional SDD workflow |
| [`AGENTS.md`](AGENTS.md) | Repository authoring, portability, release, and verification guide |
| [`CHANGELOG.md`](CHANGELOG.md) | What changed in each release |

For prompting technique and Model Context Protocol setup, use the official [Claude Code documentation](https://docs.claude.com/en/docs/claude-code) and [MCP specification](https://modelcontextprotocol.io); copied guidance drifts.

## Compatibility

Validate releases locally from a clean worktree with `scripts/release_check.sh`. It runs version agreement, plugin verification, renderer and profile contracts, payload-integrity, and release-check contracts, then prints the exact `v<version>` tag to create. Claude Code and Antigravity validators run when their CLIs are installed; otherwise they are reported as skipped. GitHub Actions runs this same deterministic gate on every push and pull request, without installing host CLIs; manually smoke-test supported hosts from the installation commands above.

## Credits

Some layered guidance adapts material from [**palkan/skills**](https://github.com/palkan/skills) by Vladimir Dementyev (MIT), including the specification-test, extraction-timing, and behavioral guidelines skills. Rich-model guidance and the vendored playbook are extracted from 37signals' open-source `fizzy`, `once-campfire`, and `writebook` applications, with a code citation behind each playbook rule.

## License

MIT
