# Indexes and Constraints Reference

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

## Making a singleton a database guarantee

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
