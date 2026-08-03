---
name: layered-conventions
description: >-
  The layered Rails 8 conventions this plugin enforces — controllers, models, services, queries,
  policies, forms, presenters, jobs, mailers, migrations, views, and testing. Use when writing or
  reviewing Rails code in a project that follows the layered profile, when you need the house rule
  for a specific layer, or when the user asks what the conventions are. WHEN NOT: deciding which
  layer a responsibility belongs to (use rails-architecture), deciding whether code is big enough to
  extract (use extraction-timing), or deciding placement from the shape of a test (use
  specification-test).
---

# Layered Rails conventions

One reference file per layer. Read the row that matches the files you are editing — not the whole
set. Each reference is the authoritative statement of its rule; do not restate it from memory.

## Profile

Before any of the rules below apply, the project must be on the layered profile: PostgreSQL, RSpec +
FactoryBot, Pundit, ViewComponent + Tailwind, and the `app/services`, `queries`, `forms`, `policies`,
`presenters` layers. [`../../AGENTS.md`](../../AGENTS.md) is the profile block, tech stack,
architecture map, and naming table — copy it into the target application's `AGENTS.md` or
`CLAUDE.md`. This profile is a deliberate divergence from the 37signals playbook; do not mix it with
the `rails-37signals` plugin.

## Router

| Editing | Read |
|---|---|
| `app/controllers/**/*.rb`, `spec/requests/**/*.rb` | [`references/controllers.md`](references/controllers.md) |
| `app/models/**/*.rb`, `spec/models/**/*.rb`, `spec/factories/**/*.rb` | [`references/models.md`](references/models.md) |
| `app/services/**/*.rb`, `spec/services/**/*.rb` | [`references/services.md`](references/services.md) |
| `app/queries/**/*.rb`, `spec/queries/**/*.rb` | [`references/queries.md`](references/queries.md) |
| `app/policies/**/*.rb`, `spec/policies/**/*.rb` | [`references/policies.md`](references/policies.md) |
| `app/jobs/**/*.rb`, `spec/jobs/**/*.rb` | [`references/jobs.md`](references/jobs.md) |
| `app/mailers/**/*.rb`, `app/views/**/*_mailer/**/*.erb`, `spec/mailers/**/*.rb` | [`references/mailers.md`](references/mailers.md) |
| `db/migrate/**/*.rb`, `db/schema.rb` | [`references/migrations.md`](references/migrations.md) |
| `app/views/**/*.erb`, `app/components/**`, `app/presenters/**` | [`references/views.md`](references/views.md) |
| `spec/**/*.rb` | [`references/testing.md`](references/testing.md) |
| any `app/**/*.rb` or `spec/**/*.rb` | [`references/anti-patterns.md`](references/anti-patterns.md) |

Always applies, regardless of path:

| Topic | Read |
|---|---|
| KISS, DRY, YAGNI, SRP, skinny everything, callback policy | [`references/principles.md`](references/principles.md) |
| Test, lint, security, database, generator, console commands | [`references/cli.md`](references/cli.md) |

## Restoring path-scoped auto-loading

Every reference keeps its original `paths:` frontmatter, so these files still work as Claude Code
rules. Copy them into the target project to get deterministic, path-triggered loading instead of
description-triggered skill invocation:

```bash
mkdir -p .claude/rules
cp ~/.claude/plugins/marketplaces/rails-engineer/rails-layered/skills/layered-conventions/references/*.md .claude/rules/
```

No editing needed — the frontmatter survives the copy.
