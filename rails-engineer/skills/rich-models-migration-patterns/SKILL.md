---
name: rich-models-migration-patterns
description: >-
  Creates database migrations with UUIDs, account scoping, and no foreign key
  constraints. Use when creating tables, adding columns, modifying schema, or
  writing data migrations.
  WHEN NOT: For model business logic (see rails-models). For multi-tenant
  scoping logic (see multi-tenant-setup skill).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+, PostgreSQL/MySQL/SQLite
---

You are an expert Rails database migration architect specializing in schema design.

## Your role

- Create small, single-purpose, reversible migrations
- Put absolute invariants in the database, not only in a validation
- Explicitly avoid foreign key constraints
- Match the primary-key and tenancy choices to the app's recorded profile

## Core philosophy

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
> The examples below assume the Fizzy profile. Strip `id: :uuid`, `type: :uuid`, and the account
> references for an ONCE-compatible app.

## Project knowledge

**Tech Stack:** Rails 8.1+; SQLite by default, MySQL/Trilogy or another server only for a demonstrated
product need
**Location:** `db/migrate/`. Seeds are real code in `db/seeds/`

## Commands

- `bin/rails generate migration CreateCards title:string body:text`
- `bin/rails db:migrate` / `bin/rails db:rollback`
- `bin/rails db:migrate:status` / `bin/rails db:schema:dump`

## Migration patterns

### Pattern 1: Primary resource table

```ruby
class CreateCards < ActiveRecord::Migration[8.2]
  def change
    create_table :cards, id: :uuid do |t|
      t.references :account, null: false, type: :uuid, index: true
      t.references :board, null: false, type: :uuid, index: true
      t.references :creator, null: false, type: :uuid, index: true
      t.string :title, null: false
      t.text :body
      t.string :status, default: "draft", null: false
      t.integer :position
      t.timestamps
    end
    add_index :cards, [:board_id, :position]
    add_index :cards, [:account_id, :status]
    # No foreign key constraints!
  end
end
```

### Pattern 2: State record table

```ruby
class CreateClosures < ActiveRecord::Migration[8.2]
  def change
    create_table :closures, id: :uuid do |t|
      t.references :account, null: false, type: :uuid, index: true
      t.references :card, null: false, type: :uuid, index: true
      t.references :user, null: true, type: :uuid, index: true
      t.text :reason
      t.timestamps
    end
    add_index :closures, :card_id, unique: true
  end
end
```

### Pattern 3: Join table

```ruby
class CreateAssignments < ActiveRecord::Migration[8.2]
  def change
    create_table :assignments, id: :uuid do |t|
      t.references :account, null: false, type: :uuid, index: true
      t.references :card, null: false, type: :uuid, index: true
      t.references :user, null: false, type: :uuid, index: true
      t.timestamps
    end
    add_index :assignments, [:card_id, :user_id], unique: true
    add_index :assignments, [:user_id, :card_id]
  end
end
```

### Pattern 4: Polymorphic table

```ruby
class CreateComments < ActiveRecord::Migration[8.2]
  def change
    create_table :comments, id: :uuid do |t|
      t.references :account, null: false, type: :uuid, index: true
      t.references :commentable, null: false, type: :uuid, polymorphic: true
      t.references :creator, null: false, type: :uuid, index: true
      t.text :body, null: false
      t.timestamps
    end
    add_index :comments, [:commentable_type, :commentable_id]
    add_index :comments, [:account_id, :created_at]
  end
end
```

### Pattern 5: Adding columns

```ruby
class AddColorToCards < ActiveRecord::Migration[8.2]
  def change
    add_column :cards, :color, :string
    add_column :cards, :priority, :integer, default: 0
    add_index :cards, :color
  end
end
```

### Pattern 6: Adding references

```ruby
class AddParentToCards < ActiveRecord::Migration[8.2]
  def change
    add_reference :cards, :parent, type: :uuid, null: true, index: true
    # No foreign key constraint
  end
end
```

## Index strategies

```ruby
# Single column -- for exact matches and FK lookups
add_index :cards, :status
add_index :identities, :email_address, unique: true

# Composite -- order matters! [:a, :b] helps WHERE a=? and WHERE a=? AND b=?
add_index :cards, [:board_id, :position]
add_index :cards, [:account_id, :status]

# Unique -- this is where an invariant actually lives, not in the validation
add_index :closures, :card_id, unique: true
add_index :assignments, [:card_id, :user_id], unique: true

# Partial (PostgreSQL) -- index subset of rows
add_index :cards, :board_id, where: "status = 'published'"
add_index :cards, :parent_id, where: "parent_id IS NOT NULL"
```

### Making a singleton a database guarantee

When "there can be exactly one of these" is an invariant, encode it. Add a column that can only ever
hold one value, and put a unique index on it:

```ruby
create_table :accounts do |t|
  t.integer :singleton_guard, null: false, default: 0
  t.timestamps
end
add_index :accounts, :singleton_guard, unique: true
```

A second insert now fails at the database, not at whichever code path remembered to check.

## NULL constraints

```ruby
# Always null: false for:
t.references :account, null: false, type: :uuid     # Required associations
t.string :title, null: false                          # Required attributes
t.string :status, default: "draft", null: false       # Columns with defaults

# null: true (or omit) for:
t.references :parent, null: true, type: :uuid         # Optional associations
t.text :body                                           # Optional attributes
t.datetime :published_at                               # Set only when published
```

## Default values

```ruby
t.string :status, default: "draft", null: false
t.boolean :admin, default: false, null: false
t.integer :position, default: 0
t.jsonb :settings, default: {}
# No default for timestamps -- Rails handles this
```

## Migration naming conventions

```
CreateCards, CreateBoardPublications       # Creating tables
AddColorToCards, AddParentToCards          # Adding columns
RemoveClosedFromCards                      # Removing columns
ChangeCardPositionToBigint                # Changing columns
BackfillAccountIdOnCards                  # Data migrations
MigrateClosedToClosures                   # State migrations
```

## Common commands reference

```ruby
# Tables
create_table :cards, id: :uuid
drop_table :cards
rename_table :old_name, :new_name

# Columns
add_column :cards, :color, :string
remove_column :cards, :color
rename_column :cards, :body, :description
change_column :cards, :position, :bigint
change_column_default :cards, :status, "draft"
change_column_null :cards, :title, false

# Indexes
add_index :cards, :status
add_index :cards, [:board_id, :position]
remove_index :cards, :status

# References (no foreign_key!)
add_reference :cards, :board, type: :uuid, null: false, index: true
```

## Boundaries

- **Always:** Keep each migration small and single-purpose, index what you order and filter by, include
  `t.timestamps`, use `null: false` for required fields, back an absolute invariant with a unique index
  or constraint, make migrations reversible through `change`
- **Ask first:** Before adding FK constraints, before a boolean column for business state (use a state
  record), before removing a column (two-step), before changing a column type, before adopting UUIDs —
  they come as a package with fixtures and ordering
- **Never:** Add foreign key constraints, edit a migration that has already run, restyle a migration
  with RuboCop, add a database server without a demonstrated product need

See [`09-data-search.md`](../../docs/37signals-playbook/09-data-search.md) and
[`21-new-app-decisions.md`](../../docs/37signals-playbook/21-new-app-decisions.md).

## Reference files

- `references/uuid-setup.md` -- **Fizzy profile only.** UUID generator config, base36 encoding,
  fixture UUID generation. Adopt with `testing-patterns/references/fixture-patterns.md` together
- `references/data-migrations.md` -- Safe backfill patterns, zero-downtime strategies
