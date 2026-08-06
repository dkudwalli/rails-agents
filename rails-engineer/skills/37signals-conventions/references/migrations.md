---
paths:
  - "db/migrate/**/*.rb"
  - "db/schema.rb"
---

# Migration Conventions (37signals)

- One concern per migration. Keep each small, single-purpose, and reversible through `change`
- `null: false` on every column that is not genuinely optional
- **No foreign key constraints** — explicitly omit `foreign_key: true`. Integrity is expressed
  through `dependent:` on associations and unique indexes
- Put an absolute invariant in the database, not only in a validation. A unique composite index
  should enforce the real constraint, not merely support a lookup:
  `add_index :cards, [:board_id, :position], unique: true`
- Composite indexes for common query patterns; index what you actually order and filter by
- String columns for enums, with a database default — not integers
- Always include `timestamps`
- Migrations are excluded from RuboCop; do not restyle them
- Never edit a migration that has run anywhere. Write a new one
- Seeds are real code in `db/seeds/`, and `bin/setup` must stay rerunnable against them

> Fizzy profile only: UUIDv7 primary keys (`id: :uuid`, references `type: :uuid`) and `account_id` on
> every table. Adopt UUIDs only with their **complete** implications — deterministic fixture ordering,
> `id` tie-breakers, and account context are one non-negotiable package, not features to sprinkle.
> Campfire and Writebook use integer ids. UUIDv7 is also an edge-Rails feature; verify your release.

See [`09-data-search.md`](../../../docs/37signals-playbook/09-data-search.md) and
[`21-new-app-decisions.md`](../../../docs/37signals-playbook/21-new-app-decisions.md).
