# rails-layered

Rails 8 development with an explicit layered architecture: services, queries, forms, policies,
presenters, and ViewComponents alongside the standard MVC directories.

**Do not install this alongside `rails-37signals`.** The two profiles disagree on database, test
framework, authorization, CSS strategy, and whether a service layer should exist at all.

## Install

```
/plugin marketplace add dkudwalli/rails-agents
/plugin install rails-layered@rails-engineer
```

Then copy the profile template into your application and fill in its profile block:

```bash
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-layered/AGENTS.md ./AGENTS.md
```

## What you get

| Component | Contents |
|---|---|
| **18 agents** | One per layer — `model-agent`, `service-agent`, `query-agent`, `policy-agent`, `form-agent`, `presenter-agent`, `viewcomponent-agent`, `controller-agent`, `job-agent`, `mailer-agent`, `migration-agent`, `rspec-agent`, `turbo-agent`, `stimulus-agent`, `tailwind-agent`, `implementation-agent`, `tdd-refactoring-agent`, `database-reviewer` |
| **14 commands** | Thin shims over the `sdd-*` and `sdd-change-*` skills, kept so the `/sdd:*` namespace and its `handoffs` chains survive. Every workflow is a skill underneath |
| **Artifact builders** | `/plan-artifact`, `/pr-artifact`, `/review-artifact` — read-only skills, invoked by name on other hosts |
| **54 skills** | The `sdd-*` spec-driven-development kit, `sdd-change-*` for small changes, artifact builders, plus `rails-architecture`, `extraction-timing`, `legacy-migration`, `specification-test`, `code-review`, `security-audit`, `accessibility-review`, `performance-optimization`, `postgres-patterns`, `migration-patterns`, `caching-strategies`, `authentication-flow` and `layered-conventions` |
| **Hooks** | Session-start project context, RuboCop and ERB Lint auto-format on edit, destructive-command guard, test/lint reminder on task completion |

## Conventions

The per-layer rules live in the `layered-conventions` skill as one reference file per layer. Each
keeps its original `paths:` frontmatter, so you can restore deterministic path-scoped loading by
copying them into your project:

```bash
mkdir -p .claude/rules
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-layered/skills/layered-conventions/references/*.md .claude/rules/
```

Without the copy, conventions load when the skill is invoked (description-triggered). With it, they
load whenever you touch a matching path, exactly as Claude Code rules do.

## Spec-driven development

Run `/sdd:init` once per project before the first `/sdd:specify`. Spec-Kit locates its root by
walking upward for a literal `.specify` directory and writes `specs/` into your repo, so it cannot
run in place from the plugin — `/sdd:init` copies the seed out. Re-run it after upgrading the plugin
to pick up new scripts and templates; it never overwrites `.specify/memory/` or `init-options.json`.

The pipeline steps and their order are listed in the [root README](../README.md#spec-driven-development).

### Artifacts

The pipeline creates a `specs/<branch-name>/` directory:

```
specs/001-user-auth/
├── spec.md           # Feature specification (/sdd:specify)
├── plan.md           # Implementation plan (/sdd:plan)
├── research.md       # Technical research & decisions (/sdd:plan)
├── data-model.md     # Entity definitions (/sdd:plan)
├── quickstart.md     # Integration scenarios (/sdd:plan)
├── contracts/        # Route and API contracts (/sdd:plan)
├── tasks.md          # Executable task list (/sdd:tasks)
├── checklists/       # Requirements quality checklists (/sdd:checklist)
└── validation-report.md  # Post-implementation drift report (/sdd:validate)
```

### Infrastructure

The seed ships at `rails-layered/specify/` and installs into your project as `.specify/`:

- **`templates/`** — Markdown templates for specs, plans, tasks, checklists, constitutions, and agent context files
- **`scripts/bash/`** — Shell scripts for branch creation, prerequisite checking, plan setup, and agent context updates
- **`memory/`** — Persistent project state (constitution, lessons learned across features)
- **`init-options.json`** — Configuration (branch numbering mode, AI agent type)

Extend it with template overrides in `.specify/templates/overrides/` and presets in
`.specify/presets/`. Overrides survive `/sdd:init` re-runs.

### Key concepts

- **Constitution** — Non-negotiable project principles validated at every planning gate
- **Lessons Learned** — Cross-feature learnings accumulate in `.specify/memory/lessons-learned.md` and feed into future planning and implementation
- **Adversarial Spec Review** — `/sdd:spec-review` challenges the spec from security, performance, edge-case, scalability, and compliance perspectives before planning begins
- **Specs are stakeholder-facing** — No implementation details; focus on WHAT and WHY
- **Checklists are "unit tests for English"** — They validate requirements quality, not implementation correctness
- **Tasks organized by user story** — Each story is independently implementable and testable (MVP-first)
- **Fresh-context implementation** — `/sdd:implement` spawns a clean specialist subagent per task, preventing context rot on large features
- **Post-implementation validation** — `/sdd:validate` uses a 4-layer hybrid approach (structural scan, test mapping, AI semantic analysis, acceptance test generation) to verify the code matches the spec

### Small changes (lightweight mode)

For bug fixes and small features that don't need the full ceremony. Three commands, no plan, no
checklists, no analysis — just specify, task, implement.

| Command | Purpose |
|---|---|
| `/sdd-change:specify` | Create a minimal change spec (problem, fix, acceptance criteria, files affected) |
| `/sdd-change:tasks` | Generate a flat 3-8 task list from the change spec |
| `/sdd-change:implement` | Execute tasks sequentially with validation |

| Situation | Use |
|---|---|
| Bug fix, patch, tweak | `/sdd-change:specify` |
| Refactor touching 1-3 files | `/sdd-change:specify` |
| Refactor touching 6+ files | `/sdd:specify` |
| New feature, multi-story epic | `/sdd:specify` |

The lightweight pipeline warns you if your change looks too complex (>3 acceptance criteria or >6
files affected) and suggests switching to the full pipeline.
