# Associations and Scopes Reference

## Association patterns

### belongs_to with defaults

```ruby
belongs_to :account, default: -> { board.account }
belongs_to :creator, class_name: "User", default: -> { Current.user }
belongs_to :board, touch: true  # Updates parent's updated_at
```

### has_many / has_one

```ruby
has_many :comments, dependent: :destroy
has_many :assignees, through: :assignments, source: :assignee
has_one :closure, dependent: :destroy
```

### Polymorphic

```ruby
has_many :attachments, as: :attachable, dependent: :destroy
has_many :events, as: :eventable, dependent: :destroy
belongs_to :notifiable, polymorphic: true
```

### Counter caches

```ruby
belongs_to :card, counter_cache: :comments_count
belongs_to :board, counter_cache: :cards_count
```

## Scope patterns

Ordering scopes are adverbs, and **always tie-break on `id`** so pagination and fixtures are
deterministic:

```ruby
# Basic ordering -- note the id tie-breaker
scope :chronologically, -> { order(created_at: :asc, id: :asc) }
scope :recently, -> { order(created_at: :desc, id: :desc) }
scope :positioned, -> { order(:position, :id) }

# Preloading is a named scope, not a scattered `includes` call
scope :with_display_dependencies, -> { includes(:creator, :board, :closure) }

# With arguments
scope :by_creator, ->(user) { where(creator: user) }
scope :created_after, ->(date) { where("created_at > ?", date) }

# Joins and where.missing (key pattern for state records)
scope :assigned_to, ->(users) { joins(:assignments).where(assignments: { assignee: users }).distinct }
scope :open, -> { where.missing(:closure) }
scope :unassigned, -> { where.missing(:assignments) }

# Complex composed scopes
scope :entropic, -> {
  open.published.where.missing(:not_now).where("updated_at < ?", 30.days.ago)
}
```
