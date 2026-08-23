---
name: rich-models-migration-patterns
description: >-
  Creates database migrations with UUIDs, account scoping, and no foreign key
  constraints. Use when creating tables, adding columns, modifying schema, or
  writing data migrations.
  Applies only in a rich-models profile app.
  WHEN NOT: A layered profile app — use layered-migration-patterns. For model business logic (see rails-models). For multi-tenant
  scoping logic (see multi-tenant-setup skill).
compatibility: Ruby 3.3+, Rails 8.0+, PostgreSQL/MySQL/SQLite
---

# Migration Patterns (37signals)

**Simple schemas. No foreign key constraints. The database enforces what must always be true.**

- **No FK constraints:** integrity comes from `dependent:` on associations plus unique indexes.
  This is an unusual position — it is deliberate, not an oversight
- **`null: false` on every column that is not genuinely optional**
- **A unique composite index enforces the real constraint**, not merely a lookup. When a rule is
  absolute, a validation alone is not enough — a validation only checks the rows Rails looks at
- **String enums with a database default**, not integers
- **One concern per migration**, `change` where it suffices, always `timestamps`
- Migrations are excluded from RuboCop. Never edit one that has run anywhere

> Fizzy profile only: **UUIDv7 primary keys** (`id: :uuid`, references `type: :uuid`) and `account_id`
> on every table. Adopt UUIDs only with their **complete** implications — deterministic fixture
> ordering, `id` tie-breakers on every ordering scope, and the account context in requests and jobs
> are one non-negotiable package, not features to sprinkle in. An ONCE-compatible app uses integer
> ids and has no account column. UUIDv7 is also an edge-Rails feature: verify it in your release.
>
> The reference examples assume the Fizzy profile. Strip `id: :uuid`, `type: :uuid`, and the account
> references for an ONCE-compatible app.

**Tech Stack:** Rails 8.1+; SQLite by default, MySQL/Trilogy or another server only for a demonstrated
product need
**Location:** `db/migrate/`. Seeds are real code in `db/seeds/`

## References

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`table-patterns.md`](references/table-patterns.md) | Resource, state-record, join, and polymorphic tables; adding columns and references; naming |
| [`indexes-and-constraints.md`](references/indexes-and-constraints.md) | Index recipes, unique invariants, singleton guards, NULL and default values |
| [`data-migrations.md`](references/data-migrations.md) | Safe backfills, zero-downtime column changes, reversibility |
| [`uuid-setup.md`](references/uuid-setup.md) | **Fizzy profile only.** UUID generator config, base36 encoding, fixture UUID generation. Adopt together with `testing-patterns/references/fixture-patterns.md` |
| [`commands.md`](references/commands.md) | Generator and rake commands, the migration method cheat sheet |

## Boundaries

- **Always:** Keep each migration small and single-purpose, index what you order and filter by, include
  `t.timestamps`, use `null: false` for required fields, back an absolute invariant with a unique index
  or constraint, make migrations reversible through `change`
- **Ask first:** Before adding FK constraints, before a boolean column for business state (use a state
  record), before removing a column (two-step), before changing a column type, before adopting UUIDs —
  they come as a package with fixtures and ordering
- **Never:** Add foreign key constraints, edit a migration that has already run, restyle a migration
  with RuboCop, add a database server without a demonstrated product need

Rules live in `37signals-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.

See [`09-data-search.md`](../../docs/37signals-playbook/09-data-search.md) and
[`21-new-app-decisions.md`](../../docs/37signals-playbook/21-new-app-decisions.md).
