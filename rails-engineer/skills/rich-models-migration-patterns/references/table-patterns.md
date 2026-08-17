# Table Migration Patterns Reference

The examples assume the Fizzy profile (UUID primary keys, `account_id` on every table). Strip
`id: :uuid`, `type: :uuid`, and the account references for an ONCE-compatible app.

## Pattern 1: Primary resource table

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

## Pattern 2: State record table

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

## Pattern 3: Join table

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

## Pattern 4: Polymorphic table

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

## Pattern 5: Adding columns

```ruby
class AddColorToCards < ActiveRecord::Migration[8.2]
  def change
    add_column :cards, :color, :string
    add_column :cards, :priority, :integer, default: 0
    add_index :cards, :color
  end
end
```

## Pattern 6: Adding references

```ruby
class AddParentToCards < ActiveRecord::Migration[8.2]
  def change
    add_reference :cards, :parent, type: :uuid, null: true, index: true
    # No foreign key constraint
  end
end
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
