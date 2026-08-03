---
name: migration-patterns
description: >-
  Worked ActiveRecord migration implementations: reversible migrations, zero-downtime column and index changes, column types, index recipes, and the pre-flight checklist. Use when creating a table, adding or removing a column, adding an index, or changing a schema on a table with production data. WHEN NOT: Model validations and associations (see model-patterns), PostgreSQL-level tuning and RLS (see postgres-patterns), or seeding data, which belongs in a rake task.
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, PostgreSQL 14+
---

# Migration Patterns

Worked implementations for schema changes. **Never modify a migration that has already run** —
add a new one.

```bash
bin/rails generate migration AddColumnToTable column:type
bin/rails db:migrate   &&   bin/rails db:rollback STEP=N
```

## Reversible migrations

Prefer `change` — Rails infers the reverse:

```ruby
class AddEmailToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email, :string, null: false
    add_index :users, :email, unique: true
  end
end
```

Use `up`/`down` when it cannot:

```ruby
class ChangeColumnType < ActiveRecord::Migration[8.1]
  def up   = change_column :items, :price, :decimal, precision: 10, scale: 2
  def down = change_column :items, :price, :integer
end
```

## Production-safe changes

**Concurrent indexes** — avoids a table lock:

```ruby
class AddEmailIndexToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  def change = add_index :users, :email, algorithm: :concurrently
end
```

**Column with a default on a large table** — three migrations, not one:

```ruby
add_column :users, :active, :boolean              # 1. Nullable column
User.in_batches.update_all(active: true)          # 2. Backfill in a job
change_column_null :users, :active, false         # 3. NOT NULL + default
change_column_default :users, :active, true
```

**Column removal** — two deploys:

```ruby
self.ignored_columns += ["old_column"]            # Deploy 1: ignore in the model
safety_assured { remove_column :users, :old_column, :string }  # Deploy 2: drop
```

## Rails 8 features

`create_virtual` (generated columns), `add_check_constraint`, and `deferrable: :deferred` on foreign
keys.

## Column types

```ruby
t.string  :name                                # varchar(255)
t.text    :description                         # unlimited text
t.citext  :email                               # case-insensitive (extension)
t.integer :count                               # integer
t.bigint  :external_id                         # bigint (external IDs)
t.decimal :price, precision: 10, scale: 2      # exact decimal
t.datetime :published_at                       # timestamp with tz
t.timestamps                                   # created_at + updated_at
t.boolean :active, null: false, default: false
t.jsonb   :metadata                            # binary JSON (indexable)
t.uuid    :token, default: "gen_random_uuid()"
t.integer :status, null: false, default: 0     # Rails enum backing
```

## Indexes

```ruby
add_index :users, :email, unique: true                     # Unique
add_index :submissions, [:entity_id, :created_at]          # Composite (order matters)
add_index :users, :email, where: "deleted_at IS NULL"      # Partial
add_index :users, :email, algorithm: :concurrently         # Non-blocking
add_index :items, :metadata, using: :gin                   # GIN for JSONB
```

Composite index column order follows the query: equality columns first, then range.

## Checklist

**Before:** reversible? `NOT NULL` constraints? indexes? foreign keys? safe on a large table?

**After:** `db:migrate` → `db:rollback` → `db:migrate` all succeed, `rspec` passes, and
`git diff db/schema.rb` shows what you expected.

**Production:** no long locks, concurrent indexes, column removal in two steps, backfills in jobs.

See `postgres-patterns` for index selection, data-type rationale, and the database-level review.
