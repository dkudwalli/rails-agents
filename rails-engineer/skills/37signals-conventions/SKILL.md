---
name: 37signals-conventions
description: >-
  The vanilla-Rails conventions this plugin enforces, extracted from fizzy, once-campfire and
  writebook — controllers and routing, rich models, concerns, jobs, mailers, migrations, views,
  plain CSS, multi-tenancy, Ruby style, and Minitest. Use when writing or reviewing Rails code in a
  project that follows the 37signals profile, when you need the house rule for a specific area, or
  when the user asks what the conventions are. WHEN NOT: working in a project whose Rails Engineer
  Profile selects layered architecture; use the layered variants unless it records a divergence.
---

# 37signals Rails conventions

One reference file per area. Read the row that matches the files you are editing — not the whole
set. Each reference cites real code in `fizzy`, `once-campfire`, or `writebook` behind every rule;
do not restate a rule from memory when the citation is one file away.

## Conditional profile reference

Read `AGENTS.md` first. This skill and the vendored playbook are reference material only when the
Rails Engineer Profile selects `Architecture: rich-models`; they do not prescribe a migration for a
layered or existing application. The managed profile records the equivalent stack choices and
deliberate divergences.

**Divergences win.** A stack the application's `AGENTS.md` records under **Deliberate divergences**
— Tailwind, RSpec, Devise, Sidekiq, Elasticsearch, a bundler — overrides every reference below that
forbids it. The references describe a target, not a verdict on the app you are in: write in the
idiom the app already runs, and leave the question of removing it to `rich-models-legacy-migration`. On an
existing application, fill that divergence list before asking this pack for code.

The vendored playbook itself lives at
[`../../docs/37signals-playbook/PLAYBOOK.md`](../../docs/37signals-playbook/PLAYBOOK.md), with the
per-topic chapters beside it.

## Router

| Editing | Read |
|---|---|
| `app/controllers/**/*.rb`, `config/routes.rb`, `test/controllers/**/*.rb` | [`references/controllers.md`](references/controllers.md) |
| `app/models/**/*.rb`, `test/models/**/*.rb` | [`references/models.md`](references/models.md) |
| `app/jobs/**/*.rb`, `test/jobs/**/*.rb` | [`references/jobs.md`](references/jobs.md) |
| `app/mailers/**/*.rb`, `app/channels/**/*.rb`, `app/views/*_mailer/**` | [`references/mailers.md`](references/mailers.md) |
| `db/migrate/**/*.rb`, `db/schema.rb` | [`references/migrations.md`](references/migrations.md) |
| `app/views/**/*.erb`, `app/helpers/**/*.rb`, `app/javascript/**/*.js` | [`references/views.md`](references/views.md) |
| `app/assets/stylesheets/**/*.css` | [`references/css.md`](references/css.md) |
| `test/**/*.rb`, `test/fixtures/**/*.yml` | [`references/testing.md`](references/testing.md) |
| any `app/**/*.rb` or `lib/**/*.rb` | [`references/style.md`](references/style.md) |
| account-scoped models, controllers, jobs, routes, migrations | [`references/multi-tenancy.md`](references/multi-tenancy.md) |

## Restoring path-scoped auto-loading

Every reference keeps its original `paths:` frontmatter, so these files still work as Claude Code
rules. Copy them into the target project to get deterministic, path-triggered loading instead of
description-triggered skill invocation:

```bash
mkdir -p .claude/rules
cp <installed rails-engineer plugin>/skills/37signals-conventions/references/*.md .claude/rules/
```

No editing needed — the frontmatter survives the copy.
