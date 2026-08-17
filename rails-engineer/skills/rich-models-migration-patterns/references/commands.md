# Migration Commands Reference

## Generating and running

- `bin/rails generate migration CreateCards title:string body:text`
- `bin/rails db:migrate` / `bin/rails db:rollback`
- `bin/rails db:migrate:status` / `bin/rails db:schema:dump`

## Common migration methods

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
