# 04 — Controllers & routing

The famous rule is "no custom controller actions". On its own that rule is impossible to follow — you
end up with `POST /cards/:id/close` renamed to something worse. The rule works because of a prior
practice, which is what this document opens with.

---

## Rule 0: name states and relationships as nouns

Before you can route everything as CRUD, every *thing a user does* has to have a noun. That vocabulary
is deliberate, and it is the highest-leverage practice in this playbook.

The nouns invented across the three apps:

| Instead of an action… | …there is a record |
|---|---|
| close / reopen a card | `Closure` — `fizzy/app/models/closure.rb` |
| mark a card important | `Card::Goldness` — `fizzy/app/models/card/goldness.rb` |
| postpone a card | `Card::NotNow` — `fizzy/app/models/card/not_now.rb` |
| publish a board publicly | `Board::Publication` — `fizzy/app/models/board/publication.rb` |
| follow / unfollow | `Watch`, `Subscription`, `Involvement` |
| mark as read | `Reading` |
| pin to the sidebar | `Pin` |
| grant board access | `Access` |
| react to a message | `Reaction`, `Boost` (campfire) |
| a page inside a book | `Leaf` / `Leafable` (writebook) |
| a save of a page | `Edit` (writebook) |
| ban a user | `Ban` (campfire) |

Adjective concerns then attach behaviour to the owner: `Closeable`, `Golden`, `Postponable`,
`Publishable`, `Watchable`, `Readable`, `Pinnable`, `Stallable`, `Triageable`.

The naming is not shy about coining words. `Goldness`, `NotNow`, `Involvement`, `Boost` are not
industry terms; they're this product's vocabulary. A slightly odd noun that exactly names the concept
beats an accurate phrase that can't be a class.

**Rule: when you catch yourself wanting a verb endpoint, name the noun that the verb creates or
destroys.** Then the routing, the model concern and the controller all fall out. See
[`03-models.md`](03-models.md) for the model half.

## Model every endpoint as CRUD on a resource

`fizzy/STYLE.md:138-153`:

```ruby
# Bad
resources :cards do
  post :close
  post :reopen
end

# Good
resources :cards do
  resource :closure
end
```

In the real routes file, `fizzy/config/routes.rb:81-108`:

```ruby
  resources :cards do
    scope module: :cards do
      resource :draft, only: :show
      resource :board
      resource :closure
      resource :column
      resource :goldness
      resource :image
      resource :not_now
      resource :pin
      resource :publish
      resource :reading
      resource :triage
      resource :watch
      resource :reading

      resources :reactions

      resources :assignments
      resource :self_assignment, only: :create
      resources :steps
      resources :taggings

      resources :comments do
        resources :reactions, module: :comments
      end
    end
  end
```

Every card operation is a nested resource. `POST /cards/5/closure` closes; `DELETE /cards/5/closure`
reopens. No `member do` block, no `post :close`.

Note `resource` (singular) for one-per-parent things and `resources` (plural) for collections — the
distinction is load-bearing, not cosmetic: `resource :closure` generates no `:id` segment, because a
card has at most one closure.

### `scope module:` to nest controllers without nesting URLs

`scope module: :cards` puts the controllers in `app/controllers/cards/` while the URLs stay
`/cards/:card_id/closure`. Used in all three:

```ruby
  resources :books, except: %i[ index show ] do          # writebook/config/routes.rb:22-32
    resource :publication, controller: "books/publications", only: %i[ show edit update ]
    resource :bookmark, controller: "books/bookmarks", only: :show

    scope module: "books" do
      namespace :leaves do
        resources :moves, only: :create
      end

      resource :search
    end
```

```ruby
  resources :rooms do                                    # once-campfire/config/routes.rb:62-74
    resources :messages

    post ":bot_key/messages", to: "messages/by_bots#create", as: :bot_messages

    scope module: "rooms" do
      resource :refresh, only: :show
      resource :settings, only: :show
      resource :involvement, only: %i[ show update ]
    end
```

### `only:` / `except:` on nearly every resource

`resource :draft, only: :show`, `resources :exports, only: [ :create, :show ]`,
`resources :passkeys, except: %i[ show new ]`, `resources :books, except: %i[ index show ]`. Routes are
declared as narrowly as the app actually needs, so `rails routes` is a truthful inventory of the
surface area. Use `%i[ ]` with inner spaces for multiples, a bare symbol for one.

### Nesting is deep, and that's fine

`fizzy/config/routes.rb:28-47` nests three levels — board → columns namespace → cards:

```ruby
  resources :boards do
    scope module: :boards do
      resources :accesses, only: :index
      resource :subscriptions
      resource :involvement
      resource :publication
      resource :entropy

      namespace :columns do
        resource :not_now
        resource :stream
        resource :closed
      end
```

### The exceptions that do exist

Reporting these honestly, because a "never" you'll immediately violate is worse than a rule with three
carve-outs. Every non-CRUD route found in the three files:

| Route | File | Why |
|---|---|---|
| `delete :clear, on: :collection` | `once-campfire/config/routes.rb:89` | clearing search history — the only true custom action found |
| `post ":bot_key/messages", to: "messages/by_bots#create"` | `once-campfire/config/routes.rb:65` | bot API authenticates by a path token |
| `get "@:message_id", to: "rooms#show"` | `once-campfire/config/routes.rb:73` | permalink syntax into a room |
| `get "join/:code"` + `post "join/:code"` | all three | invitation links with a non-id token |
| `get "tray", to: "trays#show", on: :collection` | `fizzy/config/routes.rb:119` | inside `resources :notifications` |
| `get "/:id/:slug"`, `get "/:book_id/:book_slug/:id/:slug"` | `writebook/config/routes.rb:39-40` | SEO slugs, with `constraints:` |
| `get "/collections/:collection_id/cards/:id", to: redirect { … }` | `fizzy/config/routes.rb` | legacy URL redirects |
| `get "up"`, `get "manifest"`, `get "service-worker"` | all three | framework endpoints |

Roughly one deliberate exception per app. Everything else is `resource`/`resources`.

## `direct` and `resolve`: teach the router about your models

Instead of helper methods that build paths, the router is taught how to map an object to a URL — then
`link_to comment` and `url_for(notification)` just work.

`fizzy/config/routes.rb:218-241`:

```ruby
  direct :published_board do |board, options|
    route_for :public_board, board.publication.key
  end

  direct :published_card do |card, options|
    route_for :public_board_card, card.board.publication.key, card
  end

  resolve "Comment" do |comment, options|
    options[:anchor] = ActionView::RecordIdentifier.dom_id(comment)
    route_for :card, comment.card, options
  end

  resolve "Mention" do |mention, options|
    polymorphic_url(mention.source, options)
  end

  resolve "Notification" do |notification, options|
    polymorphic_url(notification.notifiable_target, options)
  end

  resolve "Event" do |event, options|
    polymorphic_url(event.eventable, options)
  end
```

A `Comment` has no URL of its own — it resolves to its card plus an anchor. A `Notification` resolves
to whatever it points at. Views can then render a heterogeneous list of notifications with a plain
`link_to notification.title, notification`.

`writebook/config/routes.rb:42-48` uses `direct` for slugged URLs:

```ruby
  direct :book_slug do |book, options|
    route_for :slugged_book, book, book.slug, options
  end

  direct :leafable_slug do |leaf, options|
    route_for :slugged_leafable, leaf.book, leaf.book.slug, leaf, leaf.slug, options
  end
```

and `writebook/config/routes.rb:63-69` computes the route *name* from the model:

```ruby
  direct :leafable do |leaf, options|
    route_for "book_#{leaf.leafable_name}", leaf.book, leaf, options
  end
```

Campfire uses `direct` for cache-busting asset URLs — `once-campfire/config/routes.rb:28-30`:

```ruby
  direct :fresh_account_logo do |options|
    route_for :account_logo, v: Current.account&.updated_at&.to_fs(:number), size: options[:size]
  end
```

**Rule: when a path needs derivation, put it in `routes.rb` with `direct`/`resolve`, not in a helper.**

---

## Controllers

### The whole controller is HTTP plumbing around one model call

`fizzy/app/controllers/cards/goldnesses_controller.rb:1-21`, in full:

```ruby
class Cards::GoldnessesController < ApplicationController
  include CardScoped

  def create
    @card.gild

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end

  def destroy
    @card.ungild

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end
end
```

`fizzy/STYLE.md:169-177` states the intent:

> For more complex behavior, we prefer clear, intention-revealing model APIs that controllers call
> directly:
>
> ```ruby
> class Cards::GoldnessesController < ApplicationController
>   def create
>     @card.gild
>   end
> end
> ```

And `fizzy/STYLE.md:159-167` blesses the trivial case — no model method needed:

```ruby
class Cards::CommentsController < ApplicationController
  def create
    @comment = @card.comments.create!(comment_params)
  end
end
```

**Rule: a controller action does at most three things — find, call one domain method, respond.** If
you need a paragraph of logic, the paragraph belongs in the model.

### `*Scoped` concerns for the find-and-authorize preamble

Instead of repeating `before_action :set_card` in twenty nested controllers, each nesting level gets a
concern. `fizzy/app/controllers/concerns/card_scoped.rb:1-31`:

```ruby
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card, :set_board
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    end

    def set_board
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace([ @card, :card_container ], partial: "cards/container", method: :morph, locals: { card: @card.reload })
    end

    def capture_card_location
      @source_column = @card.column
      @was_in_stream = @card.awaiting_triage?
    end

    def refresh_stream_if_needed
      if @was_in_stream
        set_page_and_extract_portion_from @board.cards.awaiting_triage.latest.with_golden_first.preloaded
      end
    end
end
```

Note that it carries more than the lookup: the shared Turbo response (`render_card_replacement`) and
shared before/after bookkeeping live here too. That's why `GoldnessesController` above is 21 lines.

`fizzy/app/controllers/concerns/board_scoped.rb:1-18` is the smaller form, lookup plus a permission
check:

```ruby
module BoardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_board
  end

  private
    def set_board
      @board = Current.user.boards.find(params[:board_id])
    end

    def ensure_permission_to_admin_board
      unless Current.user.can_administer_board?(@board)
        head :forbidden
      end
    end
end
```

fizzy has `board_scoped.rb`, `card_scoped.rb`, `column_scoped.rb`, `day_timelines_scoped.rb`,
`filter_scoped.rb`; campfire has `RoomScoped` (`once-campfire/app/controllers/rooms/involvements_controller.rb:2`).

**Rule: one `*Scoped` concern per routing nesting level. `included do before_action … end`, lookup in
`private`, shared rendering alongside it.**

### Authorization is scoping, not a policy object

Look at the lookups above: `Current.user.accessible_cards.find_by!(…)`,
`Current.user.boards.find(…)`. There is no `authorize!` call and no Pundit policy — a record the
current user can't reach isn't found, and `find` raises `RecordNotFound` → 404.

Explicit checks appear only for privilege levels beyond visibility, as a `before_action` that renders
`:forbidden`:

```ruby
  before_action :ensure_permission_to_administer_card, only: %i[ destroy ]   # fizzy/app/controllers/cards_controller.rb:9

    def ensure_permission_to_administer_card
      head :forbidden unless Current.user.can_administer_card?(@card)
    end
```

The predicate (`can_administer_card?`) lives on the model. See
[`10-auth-security.md`](10-auth-security.md).

### `ApplicationController` is a list of concerns

`fizzy/app/controllers/application_controller.rb:1-13`:

```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include BlockSearchEngineIndexing
  include CurrentRequest, CurrentTimezone, SetPlatform
  include RequestForgeryProtection
  include TurboFlash, ViewTransitions
  include RoutingHeaders

  etag { "v1" }
  stale_when_importmap_changes
  allow_browser versions: :modern
end
```

`once-campfire/app/controllers/application_controller.rb:1-4`:

```ruby
class ApplicationController < ActionController::Base
  include AllowBrowser, Authentication, Authorization, BlockBannedRequests, SetCurrentRequest, SetPlatform, TrackedRoomVisit, VersionHeaders
  include Turbo::Streams::Broadcasts, Turbo::Streams::StreamName
end
```

`writebook/app/controllers/application_controller.rb:1-6`:

```ruby
class ApplicationController < ActionController::Base
  include Authentication, Authorization, VersionHeaders

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
```

**Rule: no method bodies in `ApplicationController`.** Every cross-cutting behaviour is a named concern
in `app/controllers/concerns/`. Related concerns are grouped on one `include` line.

### Class-level macros to configure the request pipeline

Concerns expose `class_methods` so a controller declares its needs in one readable line.
`fizzy/app/controllers/concerns/authentication.rb:15-31`:

```ruby
  class_methods do
    def require_unauthenticated_access(**options)
      allow_unauthenticated_access **options
      before_action :redirect_authenticated_user, **options
    end

    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :resume_session, **options
      allow_unauthorized_access **options
    end

    def disallow_account_scope(**options)
      skip_before_action :require_account, **options
      before_action :redirect_tenanted_request, **options
    end
  end
```

Read at the top of `fizzy/app/controllers/sessions_controller.rb:1-8`:

```ruby
class SessionsController < ApplicationController
  include ActionPack::Passkey::Request

  disallow_account_scope
  require_unauthenticated_access except: :destroy
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded

  layout "public"
```

Three lines describe the entire security posture of the endpoint. `rate_limit` is the Rails built-in,
not a gem.

### `params.expect`, not `permit`

```ruby
    def card_params
      params.expect(card: [ :title, :description, :image, :created_at, :last_active_at ])
    end
```
— `fizzy/app/controllers/cards_controller.rb:70-72`

```ruby
    def board_params
      params.expect(board: [ :name, :all_access, :auto_postpone_period_in_days, :public_description ])
    end
```
— `fizzy/app/controllers/boards_controller.rb:98-100`

Also for scalars: `params.expect(:email_address)`
(`fizzy/app/controllers/sessions_controller.rb:44`). `expect` raises on a missing or wrong-shaped
parameter instead of silently filtering, so a malformed request 400s rather than half-succeeding.

> Divergence: campfire and writebook predate `params.expect` and use `params.require(...).permit(...)`,
> or read `params[:x]` directly (`once-campfire/app/controllers/sessions_controller.rb:11`). Use
> `expect` on Rails ≥ 8.

`wrap_parameters` declares the JSON API shape at the top of the class —
`fizzy/app/controllers/cards_controller.rb:2`:

```ruby
  wrap_parameters :card, include: %i[ title description image created_at last_active_at ]
```

### `respond_to` blocks, with the empty-body form

The house shape, from `fizzy/app/controllers/cards_controller.rb:44-51`:

```ruby
  def destroy
    @card.destroy!

    respond_to do |format|
      format.html { redirect_to @card.board, notice: "Card deleted" }
      format.json { head :no_content }
    end
  end
```

`writebook/AGENTS.md` states the rule for default rendering explicitly:

> When using `respond_to` with default rendering, omit the `{ render }` block as it's implied.
>
> **Preferred:**
> ```ruby
> def show
>   respond_to do |format|
>     format.html
>     format.md
>   end
> end
> ```

Empty actions are left empty rather than given a body — `fizzy/app/controllers/cards_controller.rb:29-33`:

```ruby
  def show
  end

  def edit
  end
```

The `before_action`s did the work; there is nothing to write.

### Instance variables are the contract with the view

`@card`, `@board`, `@page`, `@filter`, `@selected_users` — set in `before_action`s or the action, read
in the template. No presenter or view-model object wraps them. Multiple assignment is used where
values belong together — `fizzy/app/controllers/boards_controller.rb:36-38`:

```ruby
    selected_user_ids = @board.users.ids
    @selected_users, @unselected_users = \
      @board.account.users.active.alphabetically.includes(:identity).partition { |user| selected_user_ids.include? user.id }
```

### Pagination and caching are one-liners in the action

```ruby
  def index
    set_page_and_extract_portion_from Current.user.boards.ordered_by_recently_accessed.includes(creator: :identity)
    fresh_when etag: @page.records
  end
```
— `fizzy/app/controllers/boards_controller.rb:9-12`

`set_page_and_extract_portion_from` comes from the `geared_pagination` gem (used in all three);
`fresh_when` is Rails' conditional GET. `fizzy/app/controllers/boards_controller.rb:95` shows a
composite etag:

```ruby
      fresh_when etag: [ @board, @page.records, @user_filtering, Current.account ]
```

### Branch in a private method, not in the action

`fizzy/app/controllers/boards_controller.rb:14-20` keeps the action to a two-branch `if`, each side a
named private method:

```ruby
  def show
    if @filter.used?(ignore_boards: true)
      show_filtered_cards
    else
      show_columns
    end
  end
```

## Related

- [`03-models.md`](03-models.md) — the state-as-record pattern that Rule 0 depends on.
- [`06-hotwire-javascript.md`](06-hotwire-javascript.md) — what `format.turbo_stream` responses look like.
- [`10-auth-security.md`](10-auth-security.md) — the `Authentication`/`Authorization` concerns in full.
