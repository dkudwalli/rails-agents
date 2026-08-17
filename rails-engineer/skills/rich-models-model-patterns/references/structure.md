# Model Structure Reference

**Tech Stack:** Rails 8.1+, database-backed everything; ids and tenancy per the app's profile
**Patterns:** Heavy use of namespaced concerns, default values via lambdas, `Current` for context

**Commands:**
```bash
bin/rails generate model Card title:string body:text board:references:uuid
bin/rails generate migration AddColorToCards color:string
bin/rails db:migrate
bin/rails test test/models/
bin/rails console
```

## Order within a model

```ruby
class Card < ApplicationRecord
  # 1. Concern includes
  include Assignable, Closeable, Eventable, Searchable, Watchable

  # 2. Associations
  belongs_to :account, default: -> { board.account }
  belongs_to :board, touch: true
  belongs_to :column, touch: true
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  has_many :comments, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_one :closure, dependent: :destroy

  # 3. Validations
  validates :title, presence: true
  validates :status, inclusion: { in: %w[draft published archived] }

  # 4. Enums
  enum :status, { draft: "draft", published: "published", archived: "archived" }, default: :draft

  # 5. Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :positioned, -> { order(:position) }
  scope :active, -> { open.published.where.missing(:not_now) }

  # 6. Delegations
  delegate :name, to: :board, prefix: true, allow_nil: true

  # 7. Callbacks (sparingly)
  after_create_commit :broadcast_creation

  # 8. Business logic methods
  def publish
    update!(status: :published)
    track_event "card_published"
  end

  def move_to_column(new_column)
    update!(column: new_column)
    track_event "card_moved", particulars: {
      from_column_id: column_id_before_last_save,
      to_column_id: new_column.id
    }
  end

  private

  def broadcast_creation
    broadcast_prepend_to board, :cards, target: "cards", partial: "cards/card"
  end
end
```

## Inheritance

Prefer `delegated_type` over STI. Use `class << self` for constructors that do more than `create!`:
`Room.create_for(attributes, users:)` is a named class method, not a service object.

`ApplicationRecord` stays nearly empty.
