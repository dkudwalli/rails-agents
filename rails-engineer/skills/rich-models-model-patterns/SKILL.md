---
name: rich-models-model-patterns
description: >-
  Builds rich domain models with business logic, concerns, and proper
  associations following the fat-models-over-service-objects philosophy.
  Use when creating models, adding validations, scopes, callbacks, business
  logic methods, or associations.
  WHEN NOT: Controller/routing work (use crud-patterns), concern extraction
  (use concern-patterns), state record design (use state-records).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Model Patterns (37signals)

Rich domain models over a service layer. Business logic lives in models, not in a parallel directory
of `*Service` classes.

**"Model" means "part of the domain", not "subclass of `ActiveRecord::Base`."** Value objects,
parsers, query objects, and generators live in `app/models/` next to the records — a `Struct`, a
`Search::Query`, an `HtmlScrubber`. A plain object is fine; a *layer* is not. If you are creating a
directory to hold a *category* of object, you have built a layer.

> Fizzy profile only: UUID primary keys and `account_id`/`Current.account` in the examples below.
> Check the `## Rails Engineer Profile` block in `AGENTS.md` first.

## Project knowledge

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

## Rich model vs service object

```ruby
# BAD -- service object
class CloseCardService
  def initialize(card, user)
    @card = card
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      @card.create_closure!(user: @user)
      @card.track_event("card_closed", user: @user)
    end
  end
end

# GOOD -- rich model
class Card < ApplicationRecord
  include Closeable

  def close(user: Current.user)
    create_closure!(user: user)
    track_event "card_closed", user: user
    notify_recipients_later
  end
end

# Controller simply calls:
@card.close
```

## Model structure

Order within a model:

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

## Validation patterns

```ruby
validates :title, presence: true
validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :email_address, uniqueness: { case_sensitive: false }
validates :user_id, uniqueness: { scope: :card_id }       # Join tables
validates :card, uniqueness: true                          # has_one state records
validates :body, presence: true, if: :published?           # Conditional
```

**A validation is not an invariant.** When a rule is absolute, put a unique index or a database
constraint behind it — a validation only checks the rows Rails happens to look at. See
`rich-models-migration-patterns`.

## Callbacks and enums

Callbacks are for data normalization and for work that genuinely belongs to the record's lifecycle.
Side effects a reader would not expect — emails, API calls, creating unrelated records — belong in an
explicit method the caller invokes.

```ruby
# Lambdas for one-liners; always give a callback an `if:` when it is conditional
before_validation -> { self.title = title.strip }, if: :title_changed?
before_validation :set_default_status, on: :create

# after_*_commit when the work must see committed data -- a worker cannot read an uncommitted row
after_create_commit :broadcast_creation
after_create_commit :notify_recipients_later  # the _later convention

# String enums (preferred for DB readability)
enum :status, {
  draft: "draft", published: "published", archived: "archived"
}, default: :draft, prefix: true
```

## Business logic methods

### Action methods (verbs)

```ruby
def close(user: Current.user)
  create_closure!(user: user)
  track_event "card_closed", user: user
  notify_watchers_later
end

def assign(user)
  assignments.create!(user: user) unless assigned_to?(user)
  track_event "card_assigned", particulars: { assignee_id: user.id }
end
```

### Query methods (predicates)

```ruby
def closed?
  closure.present?
end

def assigned_to?(user)
  assignees.include?(user)
end

def can_be_edited_by?(user)
  user.can_administer_card?(self) || creator == user
end
```

### Computed attributes

```ruby
def closed_at
  closure&.created_at
end

def closed_by
  closure&.user
end
```

## _later / _now convention

```ruby
# Async version (queues a job)
def notify_recipients_later
  NotifyRecipientsJob.perform_later(self)
end

# Sync version (immediate execution)
def notify_recipients_now
  recipients.each do |recipient|
    Notification.create!(recipient: recipient, notifiable: self)
  end
end

# Default to sync
def notify_recipients
  notify_recipients_now
end

# Call _later from callbacks
after_create_commit :notify_recipients_later
```

## Using Current for context

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :identity, :account
end

class Card < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { Current.account }

  def close(user: Current.user)
    create_closure!(user: user)
  end
end
```

`Current` derives dependent attributes in its writers, and offers `with_*` block wrappers rather than
having callers assign attributes ad hoc. **`Current` does not survive a queue boundary** — a job must
be given the context it needs. And it is never a place to keep data that must outlive the request.

## Inheritance

Prefer `delegated_type` over STI. Use `class << self` for constructors that do more than `create!`:
`Room.create_for(attributes, users:)` is a named class method, not a service object.

`ApplicationRecord` stays nearly empty.

See `references/model-examples.md` for complete model examples (join tables, form objects, POROs, migrations, tests).

## Boundaries

- **Always:** Put business logic in models, use namespaced concerns for organization, use bang methods
  (`create!`, `update!`), leverage associations and scopes, use `Current` for request context, default
  values via lambdas, tie-break orderings on `id`
- **Ask first:** Before adding a plain object — it is allowed, but it belongs in `app/models/` with a
  domain name, never in a category directory. Before adding a callback with a side effect. Before
  using inheritance (prefer composition via concerns)
- **Profile override:** if the app's `AGENTS.md` records `app/services` or another category
  directory under **Deliberate divergences**, that row wins over the Never rule below — write in
  the idiom the app already runs. Removing it is `rich-models-legacy-migration`'s call, not a precondition for
  the task at hand.
- **Never:** Create anemic models (data without behavior), create an `app/services/` directory, put
  business logic in controllers, rely on ambient `Current` inside a job, create models without tests

See [`03-models.md`](../../docs/37signals-playbook/03-models.md).
