---
name: crud-patterns
description: >-
  Generates RESTful controllers mapping any action to CRUD by creating new
  resources instead of custom actions. Use when adding features, creating
  controllers, designing routes, or handling state changes via REST.
  WHEN NOT: Non-REST APIs (use api-patterns), view/template work (use
  turbo-patterns), or model business logic (use model-patterns).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# CRUD Patterns (37signals)

Map any action to CRUD. When something doesn't fit standard CRUD, create a new resource.

Rule 0: **name states and relationships as nouns, then expose them as resources.** When you catch
yourself wanting a verb endpoint, name the noun the verb creates or destroys.

> Fizzy profile only: the `Current.account` scoping in the examples below, and `params.expect`.
> An ONCE-compatible application has no account layer and uses `params.require(...).permit(...)`.
> Check the `## Rails Engineer Profile` block in `AGENTS.md` before copying either.

## Project knowledge

**Tech Stack:** Rails 8.1+, Turbo, Stimulus, Importmap; queue/cache/cable per the app's profile
**Routing:** Use `scope module:` for namespacing nested resources. Put `only:`/`except:` on nearly
every route so `rails routes` stays a truthful inventory. Use `direct`/`resolve` to teach the router
about models rather than scattering path conditionals
**Controllers:** Thin, with `<Parent>Scoped` concerns per routing nesting level.
`ApplicationController` is a list of concerns, not a home for method bodies

**An action does at most three things:** find the record, call one domain method, select a response.
Branch in a private method, not in the action. Leave empty actions empty. Instance variables are the
contract with the view.

**Custom routes** are for integrations, protocol endpoints, and compatibility redirects only. Name
the exception when you add one.

**Commands:**
```bash
bin/rails routes | grep cards              # Check routes
bin/rails generate controller cards/closures  # Generate controller
bin/rails test test/controllers/           # Run controller tests
```

## Resource thinking

When asked to add functionality, ask: "What resource does this represent?"

| User request | Resource to create |
|---|---|
| "Let users close cards" | `Cards::ClosuresController` (create/destroy) |
| "Let users mark important" | `Cards::GoldnessesController` (create/destroy) |
| "Let users follow a card" | `Cards::WatchesController` (create/destroy) |
| "Let users assign cards" | `Cards::AssignmentsController` (create/destroy) |
| "Let users publish boards" | `Boards::PublicationsController` (create/destroy) |
| "Let users position cards" | `Cards::PositionsController` (update) |
| "Let users archive projects" | `Projects::ArchivalsController` (create/destroy) |

## State change controllers (singular resources)

Toggle state via POST (create) and DELETE (destroy) on a singular resource:

```ruby
# app/controllers/cards/closures_controller.rb
class Cards::ClosuresController < ApplicationController
  include CardScoped  # Provides @card, @board

  def create
    @card.close
    render_card_replacement
  end

  def destroy
    @card.reopen
    render_card_replacement
  end
end
```

## Standard CRUD controllers (plural resources)

```ruby
# app/controllers/cards/comments_controller.rb
class Cards::CommentsController < ApplicationController
  include CardScoped

  def index
    @comments = @card.comments.recent
  end

  def create
    @comment = @card.comments.create!(comment_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @card }
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
```

## Nested resource controllers

```ruby
# app/controllers/boards/columns_controller.rb
class Boards::ColumnsController < ApplicationController
  include BoardScoped

  def show
    @column = @board.columns.find(params[:id])
    @cards = @column.cards.positioned
  end

  def create
    @column = @board.columns.create!(column_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @board }
    end
  end

  def update
    @column = @board.columns.find(params[:id])
    @column.update!(column_params)
    head :no_content
  end

  def destroy
    @column = @board.columns.find(params[:id])
    @column.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @board }
    end
  end

  private

  def column_params
    params.require(:column).permit(:name, :position)
  end
end
```

## Routing patterns

### Singular resource for toggles

```ruby
resource :closure, only: [:create, :destroy]  # No :show, :edit, :new
```

### Module scoping for organization

```ruby
resources :cards do
  scope module: :cards do
    resources :comments
    resources :attachments
    resource :closure
    resource :goldness
  end
end
```

### Polymorphic routes with resolve

```ruby
resolve "Comment" do |comment, options|
  options[:anchor] = ActionView::RecordIdentifier.dom_id(comment)
  route_for :card, comment.card, options
end
```

## Scoping concerns

Provide parent resource lookup for nested controllers:

```ruby
# app/controllers/concerns/card_scoped.rb
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card
    before_action :set_board
  end

  private

  def set_card
    @card = Current.account.cards.find(params[:card_id])
  end

  def set_board
    @board = @card.board
  end

  def render_card_replacement
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@card, :card_container),
          partial: "cards/container",
          locals: { card: @card.reload }
        )
      end
      format.html { redirect_to @card }
    end
  end
end
```

Create new scoping concerns as needed:

```ruby
# app/controllers/concerns/project_scoped.rb
module ProjectScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_project
  end

  private

  def set_project
    @project = Current.account.projects.find(params[:project_id])
  end
end
```

## Response patterns

### Turbo Stream responses (preferred)

```ruby
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to @resource }
end
```

### Multi-format responses

```ruby
def create
  @resource = Model.create!(resource_params)

  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @resource }
    format.json { render json: @resource, status: :created, location: @resource }
  end
end
```

## Authorization pattern

**Authorization is scoping, not a policy object.** There is no `authorize!` call, no policy class,
and no `Pundit::NotAuthorizedError` rescue. Scope the lookup through the current actor so a record
they cannot reach is simply not found:

```ruby
@card = Current.user.accessible_cards.find_by!(number: params[:card_id])
```

`find_by!` raises `RecordNotFound` → 404. Visibility is enforced by construction, not by a check
someone can forget to write.

For a privilege check *beyond* visibility, use a one-line callback delegating to a model predicate
named `can_<verb>_<noun>?`:

```ruby
before_action :ensure_can_administer_card, only: [:destroy]

private

def ensure_can_administer_card
  head :forbidden unless Current.user.can_administer_card?(@card)
end
```

Authorization gets tested by asserting the negative in integration tests
(`assert_select "h2", text: "Manual", count: 0`), not by a policy spec.

## Files to create for a new resource

1. **Controller:** `app/controllers/[namespace]/[resource]_controller.rb`
2. **Route entry:** Add to `config/routes.rb`
3. **Test:** `test/controllers/[namespace]/[resource]_controller_test.rb`
4. **Concern (if needed):** `app/controllers/concerns/[resource]_scoped.rb`

## Boundaries

- **Always:** Map actions to CRUD, create new resources for state changes, use `<Parent>Scoped`
  concerns for lookup, enforce authorization by scoping the lookup, use strong parameters
- **Ask first:** Before adding a custom action or a non-REST route — and name the exception when you do
- **Profile override:** if the app's `AGENTS.md` records Pundit, CanCan, or another policy layer
  under **Deliberate divergences**, that row wins over the Never rule below — write in the idiom
  the app already runs. Removing it is `rich-models-legacy-migration`'s call, not a precondition for the task
  at hand.
- **Never:** Add member/collection routes for ordinary domain behaviour, add a policy object, create
  controllers without tests, put business logic in controllers

See [`04-controllers-routing.md`](../../docs/37signals-playbook/04-controllers-routing.md).
