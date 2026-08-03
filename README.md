# Rails AI Agents

A **plugin marketplace** for Ruby on Rails development, for Claude Code, OpenAI Codex, Google
Antigravity and opencode. Install one plugin and your AI assistant instantly knows Rails
conventions, TDD workflows, and production patterns.

Two conventions plugins, and you pick one:

| Plugin | Profile |
|---|---|
| **[`rails-37signals`](rails-37signals/README.md)** | Vanilla Rails — rich models, namespaced concerns, Minitest + fixtures, plain CSS, no service layer. Rebuilt from a citation-backed extraction of `fizzy`, `once-campfire`, and `writebook`. 3 agents, 24 skills |
| **[`rails-layered`](rails-layered/README.md)** | Layered architecture — services, queries, forms, policies, presenters, RSpec, Pundit, ViewComponent, Tailwind, PostgreSQL. 18 agents, 54 skills, and the [SDD kit](#spec-driven-development) |

They encode opposite architectures and **must not both be installed.** Each plugin's README lists
its full component inventory.

## Quick Start

```
/plugin marketplace add dkudwalli/rails-agents

# Then one of — never both:
/plugin install rails-37signals@rails-engineer
/plugin install rails-layered@rails-engineer
```

Then copy the profile template into your application:

```bash
# rails-37signals
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-37signals/CLAUDE.md ./CLAUDE.md

# rails-layered
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-layered/AGENTS.md ./AGENTS.md
```

Not on Claude Code? See [Other coding agents](#other-coding-agents).

### Choose an application profile first

Both plugins expect a recorded profile at the top of your `CLAUDE.md` / `AGENTS.md`. The 37signals
profile in particular is derived from three applications that **disagree with each other**, and its
own guidance forbids averaging them. Record which one you are following and which rows you deviate
from before writing code — see
[`21-new-app-decisions.md`](rails-37signals/docs/37signals-playbook/21-new-app-decisions.md).

## What you get

Both plugins ship instructions, per-layer conventions, skills, agents, and hooks.
`rails-layered` additionally ships the SDD and artifact workflows.

### Hooks

Active as soon as the plugin is enabled.

| Hook | Event | What it does |
|---|---|---|
| **SessionStart** | Session begins | Injects project context (branch, Ruby/Rails version, pending migrations) |
| **PostToolUse** | After Edit/Write | Auto-formats Ruby with RuboCop; `rails-layered` also runs ERB Lint |
| **PreToolUse** | Before Bash | Blocks destructive commands (`rm -rf`, `DROP TABLE`, force push to main); `rails-37signals` also blocks `git reset --hard` |
| **TaskCompleted** | Task marked done | Quality gate — `rails-layered` reminds you to run RSpec and RuboCop, `rails-37signals` reminds you to run `bin/ci` |

### Conventions

Claude Code auto-loads rules only from a project's own `.claude/rules/` — **plugins cannot ship
auto-loading rules.** So each plugin packages its per-layer rules as one conventions skill
(`layered-conventions`, 13 references; `37signals-conventions`, 10), whose `SKILL.md` is a router
mapping globs to the reference that governs them.

Every reference keeps its original `paths:` frontmatter, so copying them into your project restores
deterministic, path-triggered loading — no editing needed:

```bash
mkdir -p .claude/rules
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-layered/skills/layered-conventions/references/*.md \
   .claude/rules/
```

Without the copy, conventions load when the skill is invoked (description-triggered).

## Spec Driven Development

A specification-to-implementation pipeline shipped with `rails-layered`: define what you're building
before writing code, validate requirements quality, then implement from a task plan.

Run **`/sdd:init` once per project** before the first `/sdd:specify` — Spec-Kit writes `specs/` into
your repo and cannot run in place from the plugin. Re-run it after upgrading; it never overwrites
`.specify/memory/`.

| Claude Code | Skill | Purpose |
|---|---|---|
| `/sdd:init` | `sdd-init` | Install or upgrade the `.specify/` scaffolding in your project |
| `/sdd:constitution` | `sdd-constitution` | Create or update the project constitution — core principles and governance rules |
| `/sdd:specify` | `sdd-specify` | Generate a feature specification from a natural language description |
| `/sdd:clarify` | `sdd-clarify` | *(optional)* Ask up to 5 targeted questions to reduce ambiguity in the spec |
| `/sdd:spec-review` | `sdd-spec-review` | *(optional)* Adversarial review of the spec from security, performance, edge-case, scalability, and compliance perspectives |
| `/sdd:checklist` | `sdd-checklist` | *(optional)* Generate a requirements quality checklist |
| `/sdd:plan` | `sdd-plan` | Create a technical implementation plan with research, data model, and contracts |
| `/sdd:tasks` | `sdd-tasks` | Break the plan into dependency-ordered, executable tasks organized by user story |
| `/sdd:analyze` | `sdd-analyze` | Read-only consistency analysis across spec, plan, and tasks |
| `/sdd:implement` | `sdd-implement` | Execute the task plan phase-by-phase, delegating each task to its specialist agent in a fresh context |
| `/sdd:validate` | `sdd-validate` | Post-implementation drift detection — verifies code implements what the spec promises |

Run them in that order — most take an argument, as in `/sdd:specify user authentication`. Each step
hands off to the next, and the pipeline collects its artifacts in `specs/<branch-name>/`.
There is also a lightweight `/sdd-change:*` pipeline for bug fixes and small changes. Both are
documented in [`rails-layered/README.md`](rails-layered/README.md#spec-driven-development), and
[Your First SDD Feature](docs/your-first-sdd-feature.md) walks through one end to end.

On Codex, Antigravity and opencode every step is a skill — invoke `sdd-specify` directly instead of
`/sdd:specify`.

## Other coding agents

**Skills are the portable payload.** Each pack's `skills/` directory is the one canonical copy, and
each tool gets a thin manifest pointing at it — or, for opencode, none at all.

**OpenAI Codex** — same marketplace:

```bash
codex plugin marketplace add dkudwalli/rails-agents
codex plugin add rails-layered@rails-engineer      # or rails-37signals, never both
```

Skills appear namespaced as `rails-layered:<skill>`, invoked from `/skills` or by typing `$`.

**Google Antigravity** — no marketplace, `agy` installs from a directory:

```bash
git clone https://github.com/dkudwalli/rails-agents
agy plugin install ./rails-agents/rails-layered  # or rails-37signals, never both
```

It copies into `~/.gemini/config/plugins/`, shared with the Antigravity IDE, so re-run after
upgrading.

**opencode** — nothing to install. Clone the repo, then merge one key into
`~/.config/opencode/opencode.json` (that path, not `~/.opencode/`):

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": { "paths": ["~/src/rails-agents/rails-layered/skills"] }
}
```

One entry per pack covers every skill; a leading `~` resolves. Never list both packs. opencode drops
`user-invocable` frontmatter, so ask for workflow skills by name rather than as `/<name>`, and
restart it after config changes — it does not hot-reload.

### What reaches which tool

| Surface | Claude Code | Codex | Antigravity | opencode |
|---|---|---|---|---|
| Skills | yes | yes (plugin `skills/`) | yes (plugin `skills/`) | yes — no install; `skills.paths` |
| Conventions rules | yes | yes, inside the conventions skill | yes, inside the conventions skill | yes, inside the conventions skill |
| SDD / artifact workflows | yes, as `/sdd:*` etc. | yes — they are skills | yes — they are skills | yes — they are skills; ask by name |
| Slash commands themselves | yes | no — Codex prompts are `$CODEX_HOME/prompts/` only, and deprecated | top-level ones only, converted to skills | no — not shipped; every workflow is already a skill |
| Agents | yes | no — Codex subagents are TOML in `.codex/agents/` | ingested at install; not verified as subagents | no — different frontmatter vocabulary |
| Hooks | yes | manual, see below | no — incompatible schema | no — opencode hooks are JavaScript plugins |
| MCP servers | none shipped | none shipped | none shipped | none shipped, and unshippable |

Neither pack ships an MCP server. Add whatever servers you want in your own client config;
[`AGENTS.md`](AGENTS.md) § Portability records how each host spells a remote one.

### Hooks on Codex

Codex removed plugin-shipped hooks, so the packs cannot install them for you. The schema is
otherwise identical, so copy the file into your own project:

```bash
mkdir -p .codex
cp ~/.codex/plugins/cache/rails-engineer/rails-layered/*/hooks/hooks.json .codex/hooks.json
```

Then edit two entries: the `PostToolUse` matcher `Edit|Write` should be `apply_patch` (Codex's file
edit tool), and the `TaskCompleted` block never fires because Codex has no such event. The
`PreToolUse` destructive-command guard works unchanged — it is the one worth keeping.

## Documentation

| Document | Purpose |
|---|---|
| [**The 37signals Rails Playbook**](rails-37signals/docs/37signals-playbook/PLAYBOOK.md) | 23 documents of vanilla-Rails rules extracted from `fizzy`, `once-campfire`, and `writebook`, with a code citation behind each. The source of truth for `rails-37signals` |
| [Your First SDD Feature](docs/your-first-sdd-feature.md) | Step-by-step onboarding walkthrough for new developers using the SDD kit |
| [`AGENTS.md`](AGENTS.md) | Repository authoring guide — how to add a skill, agent, command, or convention rule, plus portability rules, verification, and the release checklist |

For prompting technique and Model Context Protocol setup, read the official docs rather than a copy
here — [Claude Code documentation](https://docs.claude.com/en/docs/claude-code) and the
[MCP specification](https://modelcontextprotocol.io). Guides that restate them drift silently.

## Credits

Parts of `rails-layered` adapt material from
[**palkan/skills**](https://github.com/palkan/skills) by Vladimir Dementyev (MIT), whose `layered-rails`
plugin draws on *[Layered Design for Ruby on Rails Applications](https://www.packtpub.com/en-us/product/layered-design-for-ruby-on-rails-applications-9781806114221)*.
Adapted here into this pack's own vocabulary and conventions:

| Where | What was adapted |
|---|---|
| [`skills/specification-test/`](rails-layered/skills/specification-test/SKILL.md) | The specification test — deciding layer placement from the shape of the test a piece of code needs |
| [`skills/extraction-timing/`](rails-layered/skills/extraction-timing/SKILL.md) | The 1–5 callback scoring rubric; the flog and churn thresholds |
| [`skills/extraction-timing/references/god-objects.md`](rails-layered/skills/extraction-timing/references/god-objects.md) | Churn × complexity god-object detection and the structural threshold matrix |
| [`skills/behavioral-guidelines/`](rails-layered/skills/behavioral-guidelines/SKILL.md) | The reporting rules — conditional sections, the ban on vague recommendations, the two test-review rules |

`rails-37signals` and the playbook vendored inside it are extracted from 37signals' open-source
applications — `fizzy`, `once-campfire`, and `writebook` — with a code citation behind each rule.

## License

MIT
