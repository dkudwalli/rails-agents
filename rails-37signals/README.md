# rails-37signals

Vanilla Rails the 37signals way: rich models as the domain's front door, namespaced concerns, state
records, CRUD-everything controllers, Minitest and fixtures, plain CSS, and no service layer.

Every rule cites real code in `fizzy`, `once-campfire`, or `writebook`. The vendored playbook ships
with the plugin at [`docs/37signals-playbook/`](docs/37signals-playbook/PLAYBOOK.md).

**Do not install this alongside `rails-layered`.** The two profiles disagree on database, test
framework, authorization, CSS strategy, and whether a service layer should exist at all.

## Install

```
/plugin marketplace add dkudwalli/rails-engineer
/plugin install rails-37signals@rails-engineer
```

Then copy the profile template into your application and fill in its profile block:

```bash
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-37signals/CLAUDE.md ./CLAUDE.md
```

Filling that block in is not optional ceremony. The three source applications disagree with each
other — ONCE-compatible versus Fizzy is a real fork on database, IDs, jobs, cache, and deployment —
and the playbook forbids averaging them into a hybrid stack.

## What you get

| Component | Contents |
|---|---|
| **3 agents** | `implement-agent`, `review-agent`, `refactoring-agent` |
| **24 skills** | `model-patterns`, `crud-patterns`, `concern-patterns`, `state-records`, `turbo-patterns`, `stimulus-patterns`, `css-design`, `testing-patterns`, `job-patterns`, `mailer-patterns`, `migration-patterns`, `data-search`, `auth-setup`, `multi-tenant-setup`, `content-storage`, `event-tracking`, `api-patterns`, `caching-patterns`, `tooling-ci-deploy`, `refactoring-patterns`, `legacy-migration`, `review-patterns`, `implementation-workflow`, and `37signals-conventions` |
| **Playbook** | 21 chapters plus a review checklist, each rule cited to source |
| **Hooks** | Session-start project context, RuboCop auto-format on edit, destructive-command guard (including `git reset --hard`), `bin/ci` reminder on task completion |

No slash commands, and no SDD or artifact workflows — those ship in
[`rails-layered`](../rails-layered/README.md) only, and several of them dispatch to agents that do
not exist in this pack. To port one, copy it into your project's own skills directory and re-point
`sdd-implement`'s delegation table at `implement-agent`, `review-agent`, and `refactoring-agent`.
The read-only artifact builders have no agent table and port across unchanged.

## Conventions

The per-area rules live in the `37signals-conventions` skill as one reference file per area. Each
keeps its original `paths:` frontmatter, so you can restore deterministic path-scoped loading by
copying them into your project:

```bash
mkdir -p .claude/rules
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-37signals/skills/37signals-conventions/references/*.md .claude/rules/
```

Without the copy, conventions load when the skill is invoked (description-triggered). With it, they
load whenever you touch a matching path, exactly as Claude Code rules do.
