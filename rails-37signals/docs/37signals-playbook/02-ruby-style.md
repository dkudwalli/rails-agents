# 02 — Ruby style

`fizzy/STYLE.md` is the only written style guide in the three repositories. Campfire and Writebook
were built before it existed, so each rule below says whether the older code actually follows it.
The second half covers conventions `STYLE.md` never mentions but all three obey.

Baseline: `rubocop-rails-omakase` in all three. `02` is about what omakase doesn't decide.

---

## Rules from STYLE.md, verified

### Expanded conditionals over guard clauses

`fizzy/STYLE.md:10-32`:

```ruby
# Bad
def todos_for_new_group
  ids = params.require(:todolist)[:todo_ids]
  return [] unless ids
  @bucket.recordings.todos.find(ids.split(","))
end

# Good
def todos_for_new_group
  if ids = params.require(:todolist)[:todo_ids]
    @bucket.recordings.todos.find(ids.split(","))
  else
    []
  end
end
```

> This is because guard clauses can be hard to read, especially when they are nested.

**This one is real and measurable.** Count of `return if` / `return unless` in `app/`:

| repo | guard clauses | lines of Ruby in `app/` |
|---|---|---|
| fizzy | 14 | 11,299 |
| once-campfire | 1 | 3,248 |
| writebook | 1 | 1,767 |

Roughly one guard clause per thousand lines. If your codebase opens most methods with
`return unless`, that is the single biggest stylistic difference from this code.

The idiom that replaces it — assignment inside the condition,
`fizzy/app/controllers/sessions_controller.rb:14-22`:

```ruby
  def create
    if identity = Identity.find_by(email_address: email_address)
      sign_in identity
    elsif Account.accepting_signups?
      sign_up
    else
      redirect_to_fake_session_magic_link email_address
    end
  end
```

Same shape in the older app, `once-campfire/app/controllers/sessions_controller.rb:10-17`:

```ruby
  def create
    if user = User.active.authenticate_by(email_address: params[:email_address], password: params[:password])
      start_new_session_for user
      redirect_to post_authenticating_url
    else
      render_rejection :unauthorized
    end
  end
```

Note `if x = y` with a single `=`. RuboCop's omakase configuration permits it; it is intentional, not a
typo for `==`.

The sanctioned exceptions, `fizzy/STYLE.md:34-37`:

> As an exception, we sometimes use guard clauses to return early from a method:
> * When the return is right at the beginning of the method.
> * When the main method body is not trivial and involves several lines of code.

### Method order within a class

`fizzy/STYLE.md:51-57`:

> 1. `class` methods
> 2. `public` methods with `initialize` at the top.
> 3. `private` methods

### Vertical order follows invocation order

`fizzy/STYLE.md:59-61` — a method appears above the methods it calls, so reading downward follows
execution. `fizzy/app/controllers/sessions_controller.rb` follows it: `create` (line 14) calls
`sign_in` and `sign_up`, both defined below in `private`.

**Corollary for editing:** when you add a private method, put it directly below its caller, not at the
bottom of the class.

### `!` only marks a variant, never destructiveness

`fizzy/STYLE.md:103`:

> As a general rule, we only use `!` for methods that have a correspondent counterpart without `!`. In
> particular, we don't use `!` to flag destructive actions. There are plenty of destructive methods in
> Ruby and Rails that do not end with `!`.

So `Card#close` destroys a record and has no bang; `create_closure!` has one because
`create_closure` exists (`fizzy/app/models/card/closeable.rb:35`). Don't write `publish!` to warn the
reader that something serious happens.

### No blank line under `private`, and indent what follows

`fizzy/STYLE.md:105-124`:

```ruby
class SomeClass
  def some_method
    # ...
  end

  private
    def some_private_method_1
      # ...
    end

    def some_private_method_2
      # ...
    end
end
```

**Verified across all three** — files with a class-level `private` that use the indented style:

| repo | indented | total |
|---|---|---|
| fizzy | 166 | 174 |
| once-campfire | 54 | 62 |
| writebook | 29 | 30 |

This is unusual enough that RuboCop's default `Layout/IndentationConsistency` would object;
`rubocop-rails-omakase` configures it to expect exactly this. It is the fastest visual tell that code
came from this lineage.

`fizzy/STYLE.md:126-136` adds the module case: a module with only private methods puts `private` at
the top with a blank line after and no indentation. Rare in practice — `fizzy/app/models/card/`
concerns instead mix public and private with the indented form
(`fizzy/app/models/card/broadcastable.rb:10-18`).

### CRUD controllers and the model relationship

`fizzy/STYLE.md:138-153` and `155-183` are covered in [`04-controllers-routing.md`](04-controllers-routing.md)
and [`01-philosophy.md`](01-philosophy.md) respectively.

### `_later` / `_now` for async

`fizzy/STYLE.md:185-214` — see [`08-jobs-async.md`](08-jobs-async.md).

---

## Conventions STYLE.md doesn't mention

### Whitespace-aligned columns when a group of lines are variations of each other

`fizzy/app/models/card.rb:22-24`:

```ruby
  scope :reverse_chronologically, -> { order created_at:     :desc, id: :desc }
  scope :chronologically,         -> { order created_at:     :asc,  id: :asc  }
  scope :latest,                  -> { order last_active_at: :desc, id: :desc }
```

`once-campfire/app/models/message.rb:31-37`:

```ruby
  def content_type
    case
    when attachment?    then "attachment"
    when sound.present? then "sound"
    else                     "text"
    end.inquiry
  end
```

Alignment is used to make a set of parallel lines readable as a table. Don't align unrelated
assignments.

### Subjectless `case` instead of `if/elsif` chains

`once-campfire/app/models/message.rb:32` — bare `case` with `when <predicate> then <value>`. Reads as
a decision table.

### `.inquiry` to turn a string into a predicate

`once-campfire/app/models/message.rb:36` — `.inquiry` makes `message.content_type.attachment?` work in
a view. Also `writebook/app/models/leafable.rb:18-20`:

```ruby
    def leafable_name
      @leafable_name ||= ActiveModel::Name.new(self).singular.inquiry
    end
```

### Keyword arguments defaulting to `Current`

`fizzy/app/models/card/closeable.rb:31` — `def close(user: Current.user)`. The caller normally omits
it; tests and background jobs pass it explicitly. Same idea in
`fizzy/app/models/concerns/eventable.rb:8`:

```ruby
  def track_event(action, creator: Current.user, board: self.board, **particulars)
```

Note the shorthand hash values (`creator:`, `board:`, `particulars:`) on line 10 of that file — Ruby
3.1+ omitted-value syntax, used consistently.

### Anonymous block forwarding

`fizzy/app/models/current.rb:21-27`:

```ruby
  def with_account(value, &)
    with(account: value, &)
  end

  def without_account(&)
    with(account: nil, &)
  end
```

`&` with no name when the block is only passed through. Also
`fizzy/app/helpers/forms_helper.rb:6-10`.

### `it` in single-argument blocks

`fizzy/app/models/color.rb:9` — `COLORS.find { |it| it.value == value }`. Ruby 3.4's implicit `it` is
adopted where the block parameter carries no information.

### Struct for value objects, `class << self` for class-method groups

`fizzy/app/models/color.rb:1-22`:

```ruby
Color = Struct.new(:name, :value)

class Color
  class << self
    # Finds a Color by its CSS value (e.g. "var(--color-card-4)").
    def for_value(value)
```

Reopening the struct to add behaviour, and `class << self` rather than repeated `def self.`.

### Comments explain *why*, and flag cross-file coupling

Comments are sparse. Where they exist they justify a decision that the code cannot state — and
notably, they mark duplicated logic that must stay in sync.
`fizzy/app/javascript/controllers/bubble_controller.js:55`:

```javascript
  // Keep in sync with Card::Stallable#stalled? in app/models/card/stallable.rb
```

`fizzy/app/models/color.rb:14-16`:

```ruby
      # Broken exports serialized Color structs instead of raw CSS values,
      # producing JSON like {"name":"Lime","value":"var(--color-card-4)"}.
      # Parse it and extract the value.
```

**Rule: don't narrate what the code does; record the reason, the history, or the coupling.**

### Naming

- Concerns are adjectives: `Closeable`, `Postponable`, `Stallable`, `Triageable`, `Searchable`,
  `Broadcastable`, `Positionable`, `Editable`, `Mentionee`.
- Records that represent a state are nouns: `Closure`, `Goldness`, `NotNow`, `Publication`. See
  [`04-controllers-routing.md`](04-controllers-routing.md) — this is the keystone practice.
- Methods that enqueue end in `_later`; their synchronous partners end in `_now`.
- Predicates end in `?` and read as English: `filled?`, `awaiting_triage?`, `accepting_signups?`.

## Related

- [`01-philosophy.md`](01-philosophy.md) — why appearance rules are worth having at all.
- [`03-models.md`](03-models.md) — where these conventions land in practice.
- [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md) — the RuboCop setup that enforces the mechanical
  half of this.
