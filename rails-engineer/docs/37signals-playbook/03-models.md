# 03 — Models

"Rich domain model" is easy to say and usually produces a 2,000-line `User` class. This is how these
apps keep models rich *and* readable: one class per concept, and the concepts are split into
namespaced concerns rather than dumped into one file.

---

## The class body is a table of contents, not the implementation

`fizzy/app/models/card.rb:1-26`:

```ruby
class Card < ApplicationRecord
  include Accessible, Assignable, Attachments, Broadcastable, Closeable, Colored, Commentable,
    Entropic, Eventable, Exportable, Golden, Mentions, Multistep, Pinnable, Postponable, Promptable,
    Readable, Searchable, Stallable, Statuses, Storage::Tracked, Taggable, Triageable, Watchable

  belongs_to :account, default: -> { board.account }
  belongs_to :board
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  has_many :reactions, -> { order(:created_at) }, as: :reactable, dependent: :delete_all
  has_one_attached :image, dependent: :purge_later

  has_rich_text :description
```

24 concerns on one line. `Card` is the most feature-laden model in the three apps, and
`app/models/card.rb` is **95 lines**. The features live in `app/models/card/` — 26 files at its top
level, 28 including nested ones.

`fizzy/app/models/user.rb:1-4` shows the same idiom plus a documented ordering dependency:

```ruby
class User < ApplicationRecord
  include Accessor, Assignee, Attachable, Avatar, Configurable, EmailAddressChangeable,
    Mentionable, Named, Notifiable, Role, Searcher, Watcher
  include Timelined # Depends on Accessor
```

**Rules:**
- One `include` listing concerns alphabetically. A second `include` only to express load order, with a
  comment saying why.
- What stays in the class body: associations, `has_rich_text`/`has_one_attached`, validations, the
  scopes that order the base relation, and the two or three methods that belong to no feature.
- Everything that is a *feature* goes into a concern.

## Concerns are namespaced under the model, not pooled in `concerns/`

`fizzy/app/models/card/` contains `closeable.rb`, `golden.rb`, `postponable.rb`, `stallable.rb`,
`taggable.rb`, `watchable.rb`, … — each defining `module Card::Closeable`, not `module Closeable`.

`app/models/concerns/` is reserved for the genuinely shared ones. In fizzy that directory holds only
six files plus a `storage/` subdirectory: `attachments.rb`, `eventable.rb`, `filterable.rb`,
`mentions.rb`, `notifiable.rb`, `searchable.rb` — the concerns included by more than one model. Same
split in writebook:
`app/models/concerns/` has `authorization.rb` and `positionable.rb`; `book/` has `accessable.rb` and
`sluggable.rb`; `leaf/` has `editable.rb` and `searchable.rb`.

> Divergence: campfire's `app/models/concerns/` is empty — all its concerns are model-namespaced
> (`message/`, `room/`, `user/`, `account/`, `membership/`).

**Rule: a concern goes in `app/models/<model>/` unless two models include it. Then, and only then,
promote it to `app/models/concerns/`.** This is what keeps `Card`'s 25 features from colliding with
`Comment`'s in one flat namespace — both have a `Searchable`, and they are different files.

## A concern is a vertical slice: associations, scopes, predicates, verbs

`fizzy/app/models/card/closeable.rb:1-48`, in full:

```ruby
module Card::Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy

    scope :closed, -> { joins(:closure) }
    scope :open, -> { where.missing(:closure) }

    scope :recently_closed_first, -> { closed.order(closures: { created_at: :desc }) }
    scope :closed_at_window, ->(window) { closed.where(closures: { created_at: window }) }
    scope :closed_by, ->(users) { closed.where(closures: { user_id: Array(users) }) }
  end

  def closed?
    closure.present?
  end

  def open?
    !closed?
  end

  def closed_by
    closure&.user
  end

  def closed_at
    closure&.created_at
  end

  def close(user: Current.user)
    unless closed?
      transaction do
        not_now&.destroy
        create_closure! user: user
        track_event :closed, creator: user
      end
    end
  end

  def reopen(user: Current.user)
    if closed?
      transaction do
        closure&.destroy
        track_event :reopened, creator: user
      end
    end
  end
end
```

Everything about closing a card is in that one file: the association, the query scopes, the
predicates, the readers, and the two state-changing verbs. Nothing about closing lives anywhere else.

**Rule: a concern owns its association. If you add `has_one :closure` to the class body and the
behaviour to a concern, you've split the feature in two.**

## Represent a state as a record, not a boolean column

This is the practice everything else hangs off. Instead of `cards.closed_at` and `cards.golden`
columns, there are `Closure` and `Card::Goldness` records.

`fizzy/app/models/closure.rb:1-5`, the entire model:

```ruby
class Closure < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :card, touch: true
  belongs_to :user, optional: true
end
```

`fizzy/app/models/card/goldness.rb:1-4`:

```ruby
class Card::Goldness < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :card, touch: true
end
```

What you get for those four lines:
- **Who and when, free.** `Closure` has `user` and `created_at`, so `closed_by` and `closed_at` are
  reads, not extra columns (`card/closeable.rb:23-29`).
- **Scopes that are joins.** `scope :closed, -> { joins(:closure) }` and
  `scope :open, -> { where.missing(:closure) }` — no `where(closed: true)`, no null handling.
- **A URL.** `Closure` is a resource, so closing a card is `POST /cards/:id/closure` and reopening is
  `DELETE`. See [`04-controllers-routing.md`](04-controllers-routing.md).

The same shape appears as `Card::NotNow`, `Card::ActivitySpike`, `Board::Publication`, `Pin`, `Watch`,
`Reaction`, `Access`, `Boost` (campfire), `Edit` (writebook).

**Rule: when a boolean or timestamp column would need "who did it" or "when" or an endpoint, make it a
record with a `has_one`.** The predicate becomes `closure.present?` and the verb becomes
`create_closure!`.

## Verb methods are transactional and event-emitting

`fizzy/app/models/card/golden.rb:15-21` is the minimal form:

```ruby
  def gild
    create_goldness! unless golden?
  end

  def ungild
    goldness&.destroy
  end
```

Idempotent (`unless golden?`, safe-navigating `&.destroy`), named as a domain verb rather than
`set_golden`. Where more than one write is involved, wrap it — `card/closeable.rb:32-38` opens a
`transaction`, destroys the `not_now`, creates the closure, and tracks an event.

## Events are a concern, not a callback pile

`fizzy/app/models/concerns/eventable.rb:1-25`:

```ruby
module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy
  end

  def track_event(action, creator: Current.user, board: self.board, **particulars)
    if should_track_event?
      board.events.create!(action: "#{eventable_prefix}_#{action}", creator:, board:, eventable: self, particulars:)
    end
  end

  def event_was_created(event)
  end

  private
    def should_track_event?
      true
    end

    def eventable_prefix
      self.class.name.demodulize.underscore
    end
end
```

Note the two hooks meant to be overridden — `should_track_event?` and `event_was_created` — with
default no-op implementations. That is how a shared concern stays configurable without options
hashes.

## `Current` is where request context lives, and it derives the rest

`fizzy/app/models/current.rb:1-27`:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :identity, :account
  attribute :http_method, :request_id, :user_agent, :ip_address, :referrer

  def session=(value)
    super(value)

    if value.present?
      self.identity = session.identity
    end
  end

  def identity=(identity)
    super(identity)

    if identity.present?
      self.user = identity.users.find_by(account: account)
    end
  end

  def with_account(value, &)
    with(account: value, &)
  end

  def without_account(&)
    with(account: nil, &)
  end
end
```

Setting `Current.session` cascades to `identity` and then to `user` — assign one thing, and the rest
of the request has everything. Compare the single-tenant version,
`writebook/app/models/current.rb:1-15`:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user

  def session=(value)
    super(value)

    if value.present?
      self.user = session.user
    end
  end

  def account
    Account.first
  end
end
```

`account` is `Account.first` because a ONCE install has exactly one. Campfire's is identical plus
`attribute :request` and `delegate :host, :protocol, to: :request, prefix: true, allow_nil: true`
(`once-campfire/app/models/current.rb:2-4`).

**Rules:**
- Override the writer to derive dependent attributes; don't make callers set three things.
- Use `Current` as the default for keyword arguments in models (`user: Current.user`) so tests and
  jobs can pass it explicitly.
- Provide `with_*` wrappers for scoped execution rather than assigning and restoring by hand.

## Scope conventions

From `fizzy/app/models/card.rb:22-26`:

```ruby
  scope :reverse_chronologically, -> { order created_at:     :desc, id: :desc }
  scope :chronologically,         -> { order created_at:     :asc,  id: :asc  }
  scope :latest,                  -> { order last_active_at: :desc, id: :desc }
  scope :with_users,              -> { preload(creator: [ :avatar_attachment, :account ], assignees: [ :avatar_attachment, :account ]) }
  scope :preloaded,               -> { with_users.preload(:column, :tags, :steps, :closure, :goldness, :activity_spike, :image_attachment, reactions: :reacter, board: [ :entropy, :columns ], not_now: [ :user ]).with_rich_text_description_and_embeds }
```

- **Ordering scopes are adverbs**: `chronologically`, `reverse_chronologically`, `alphabetically`
  (`fizzy/app/models/board.rb:13`), `ordered` (`once-campfire/app/models/message.rb:14`),
  `positioned` (`writebook/app/models/concerns/positionable.rb:8`).
- **Always break ties with `id`.** Every ordering scope above orders by a timestamp *and* `id`.
- **Preloading is a named scope, not caller-side `includes`.** `with_users` and `preloaded` are
  declared once next to the model and reused by every controller — that's how N+1 fixes stay fixed.
  Campfire splits them finer: `with_creator`, `with_attachment_details`, `with_boosts`
  (`once-campfire/app/models/message.rb:15-21`).
- **Parameterised dispatch scopes** replace controller conditionals — `Card.indexed_by(index)` and
  `Card.sorted_by(sort)` (`fizzy/app/models/card.rb:28-48`) map a URL param to a scope with a `case`,
  so the controller passes `params[:sort]` straight through.

## Association extensions instead of a manager object

`once-campfire/app/models/room.rb:1-18`:

```ruby
class Room < ApplicationRecord
  has_many :memberships, dependent: :delete_all do
    def grant_to(users)
      room = proxy_association.owner
      Membership.insert_all(Array(users).collect { |user| { room_id: room.id, user_id: user.id, involvement: room.default_involvement } })
    end

    def revoke_from(users)
      destroy_by user: users
    end

    def revise(granted: [], revoked: [])
      transaction do
        grant_to(granted) if granted.present?
        revoke_from(revoked) if revoked.present?
      end
    end
  end
```

`room.memberships.revise(granted: …, revoked: …)` — the block on `has_many` is where collection
behaviour goes. Fizzy uses the same call shape for board access:
`@board.accesses.revise granted: grantees, revoked: revokees` (`fizzy/app/controllers/boards_controller.rb:43`).

## `class << self` for class-level constructors

`once-campfire/app/models/room.rb:32-44`:

```ruby
  class << self
    def create_for(attributes, users:)
      transaction do
        create!(attributes).tap do |room|
          room.memberships.grant_to users
        end
      end
    end

    def original
      order(:created_at).first
    end
  end
```

A creation that has to do more than `create!` becomes a named class method, not a service object.

## `delegated_type` for a heterogeneous collection

`writebook/app/models/leaf.rb:1-16`:

```ruby
class Leaf < ApplicationRecord
  include Editable, Positionable, Searchable

  belongs_to :book, touch: true
  delegated_type :leafable, types: Leafable::TYPES, dependent: :destroy
  positioned_within :book, association: :leaves, filter: :active

  delegate :searchable_content, to: :leafable

  enum :status, %w[ active trashed ].index_by(&:itself), default: :active

  scope :with_leafables, -> { includes(:leafable) }

  def slug
    title.parameterize.presence || "-"
  end
end
```

The counterpart concern, `writebook/app/models/leafable.rb:1-25`:

```ruby
module Leafable
  extend ActiveSupport::Concern

  TYPES = %w[ Page Section Picture ]

  included do
    has_one :leaf, as: :leafable, inverse_of: :leafable, touch: true
    has_one :book, through: :leaf

    delegate :title, to: :leaf
  end

  def searchable_content
    nil
  end

  class_methods do
    def leafable_name
      @leafable_name ||= ActiveModel::Name.new(self).singular.inquiry
    end
  end
```

`Leaf` holds position, status and title; `Page`/`Section`/`Picture` hold their own content. Shared
behaviour lives in the `Leafable` concern with a default `searchable_content` the types override. This
is preferred over STI — campfire uses STI for `Rooms::Open`/`Closed`/`Direct`
(`once-campfire/app/models/room.rb:25-28`), which is the older pattern of the two.

> Divergence: campfire uses STI (`scope :opens, -> { where(type: "Rooms::Open") }` plus `is_a?`
> predicates at `room.rb:51-61`); writebook and fizzy prefer `delegated_type` and `has_one` state
> records. Prefer the newer approach unless the subtypes genuinely share every column.

## Enums use the hash-from-array idiom

```ruby
enum :status, %w[ drafted published ].index_by(&:itself)                                  # fizzy/app/models/card/statuses.rb:5
enum :status, %w[ active trashed ].index_by(&:itself), default: :active                    # writebook/app/models/leaf.rb:10
enum :theme, %w[ black blue green magenta orange violet white ].index_by(&:itself), suffix: true, default: :blue  # writebook/app/models/book.rb:10
```

`%w[…].index_by(&:itself)` gives string-backed enums, so the database column is readable and adding a
value doesn't renumber anything.

## Class-level macros to configure a concern per-model

`writebook/app/models/concerns/positionable.rb:17-32` defines a macro that the including model calls
with its own parameters:

```ruby
  class_methods do
    def positioned_within(parent, association:, filter:)
      define_method :positioning_parent do
        send(parent)
      end

      define_method :all_positioned_siblings do
        positioning_parent.send(association).send(filter).positioned
      end

      define_method :other_positioned_siblings do
        all_positioned_siblings.excluding(self)
      end

      private :positioning_parent, :all_positioned_siblings, :other_positioned_siblings
    end
  end
```

Used as `positioned_within :book, association: :leaves, filter: :active`
(`writebook/app/models/leaf.rb:6`). This is the Rails-native alternative to passing an options hash
into `include`.

## Callbacks: lambdas for one-liners, `_later` for anything slow

`fizzy/app/models/card.rb:15-20`:

```ruby
  before_save :set_default_title, if: :published?
  before_create :assign_number

  after_save   -> { board.touch }, if: :published?
  after_touch  -> { board.touch }, if: :published?
  after_update :handle_board_change, if: :saved_change_to_board_id?
```

- Inline lambda when the body is one expression; a private method name when it isn't.
- Always `if:` — callbacks are conditional by default here.
- Anything that talks to the network or does bulk work is enqueued, not run inline:
  `handle_board_change` ends with `remove_inaccessible_notifications_later` and
  `clean_inaccessible_data_later` (`fizzy/app/models/card.rb:84-85`). See
  [`08-jobs-async.md`](08-jobs-async.md).
- `after_create_commit`, not `after_create`, when the work must see committed data —
  `once-campfire/app/models/message.rb:12`: `after_create_commit -> { room.receive(self) }`.

## Defaulted `belongs_to` instead of controller assignment

```ruby
belongs_to :account, default: -> { board.account }               # fizzy/app/models/card.rb:6
belongs_to :creator, class_name: "User", default: -> { Current.user }   # fizzy/app/models/card.rb:8
belongs_to :account, default: -> { creator.account }              # fizzy/app/models/board.rb:5
belongs_to :creator, class_name: "User", default: -> { Current.user }   # once-campfire/app/models/room.rb:23
```

Ownership and tenancy are derived by the model. A controller never writes
`creator: Current.user` — and because it never does, it can't forget to.

## `ApplicationRecord` stays nearly empty

`writebook/app/models/application_record.rb:1-3`:

```ruby
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
```

`fizzy/app/models/application_record.rb:1-5` adds exactly one line
(`configure_replica_connections`). The base class is not a dumping ground for helpers.

## Related

- [`04-controllers-routing.md`](04-controllers-routing.md) — the state-as-record rule is what makes
  every endpoint plain CRUD; read it next.
- [`08-jobs-async.md`](08-jobs-async.md) — the `_later`/`_now` half of callbacks.
- [`09-data-search.md`](09-data-search.md) — the schema side: UUID keys, counter columns, search rows.
