# 05 — Views & helpers

Plain ERB, small partials, and helpers that build tags. No presenters, no view models, no
ViewComponent, no template language other than ERB.

---

## Partials are small, and there are a lot of them

Measured across the whole `app/views` tree:

| repo | ERB files | lines | mean |
|---|---|---|---|
| fizzy | 330 | 5,895 | 18 |
| once-campfire | 78 | 2,228 | 29 |
| writebook | 74 | 1,725 | 23 |

The **largest** template in fizzy's 330 is `layouts/mailer.html.erb` at 158 lines; the largest
non-layout is `notifications/settings/_browser.html.erb` at 109. Everything else is under 100 and most
are under 20.

That is the target: a template you can read without scrolling. A 300-line template is not a style
violation here, it's a structural one — it means concepts that deserved names didn't get them.

## A template's job is to name and order its children

`fizzy/app/views/cards/_container.html.erb:1-44` — a 44-line template that is almost entirely
`render` calls:

```erb
<section id="<%= dom_id(card, :card_container) %>" class="card-perma" style="--card-color: <%= card.color %>;" data-controller="dialog-manager bridge--form">
  <% cache card do %>
    <div class="card-perma__actions card-perma__actions--left">
      <%= render "cards/container/gild", card: card if card.published? && !card.closed? %>
      <%= render "cards/container/image", card: card %>
    </div>

    <div class="card-perma__bg">
      <%= card_article_tag card, class: "card" do %>
        <header class="card__header">
          <%= render "cards/display/perma/board", card: card %>
          <%= render "cards/display/perma/tags", card: card %>
        </header>
```

Note the directory depth: `cards/container/`, `cards/display/perma/`, `cards/display/common/`,
`cards/display/preview/`. Partials are organised into folders by the context they render in, not
flattened into `cards/` with long prefixed names.

**Rules:**
- Pass locals explicitly (`card: card`). Don't rely on instance variables inside partials.
- Conditional rendering goes on the `render` line (`… if card.published? && !card.closed?`) rather than
  wrapping it in an `if` block, when it fits.
- Nest partial directories to mirror the composition.

## `render collection:` with `cached: true`, and `cache` in the partial

`once-campfire/app/views/messages/index.html.erb:1` is the entire index template:

```erb
<%= render partial: "messages/message", collection: @messages, cached: true %>
```

and the partial opens with its own cache block, `once-campfire/app/views/messages/_message.html.erb:1-4`:

```erb
<%# Be sure to check/update messages/_template.html.erb when changing this file %>

<% cache message do %>
  <%= message_tag message do %>
```

`cached: true` turns the collection render into one multi-read against the cache store. Russian-doll
caching is used throughout: `fizzy/app/views/cards/_container.html.erb:2` wraps most of the card in
`cache card do`, and `writebook/app/views/books/index.html.erb:27` uses a composite key:

```erb
<% cache [ @books, signed_in? ] do %>
```

Including `signed_in?` in the key because the markup differs for signed-in users — cache keys carry
every input that changes the output.

**Rule: cache at the partial that owns a record, key it on the record, and add any non-record input to
the key array.** `touch: true` on the `belongs_to` side (`fizzy/app/models/card.rb:7` via
`belongs_to :board`; `once-campfire/app/models/message.rb:4` `belongs_to :room, touch: true`) is what
makes the outer dolls expire.

## `<%# comment %>` to flag a template that must be kept in sync

`once-campfire/app/views/messages/_message.html.erb:1`:

```erb
<%# Be sure to check/update messages/_template.html.erb when changing this file %>
```

Campfire renders messages twice — server-side and as a client-side template for optimistic sending
(`_template.html.erb`). The duplication is deliberate and the comment is the guard. Same discipline as
the JS/Ruby sync comment noted in [`02-ruby-style.md`](02-ruby-style.md).

## Turbo Stream templates are tiny and declarative

`once-campfire/app/views/messages/create.turbo_stream.erb:1` — the whole file:

```erb
<%= turbo_stream.append dom_id(@message.room, :messages), @message %>
```

`fizzy/app/views/cards/update.turbo_stream.erb:1-10` shows the multi-target form:

```erb
<% container_partial = @card.drafted? ? "cards/drafts/container" : "cards/container" %>
<%= turbo_stream.replace dom_id(@card, :card_container), partial: container_partial, method: :morph, locals: { card: @card.reload } %>

<%= turbo_stream.update dom_id(@card, :edit) do %>
  <%= render "cards/container/content_display", card: @card %>
<% end %>

<%= turbo_stream.replace dom_id(@card, :card_closure_toggle) do %>
  <%= render "cards/container/closure", card: @card %>
<% end %>
```

Points worth copying: `dom_id(record, :suffix)` for every target so ids are never hand-written;
`method: :morph` on replace so DOM state survives; `@card.reload` so the partial sees post-callback
state. See [`06-hotwire-javascript.md`](06-hotwire-javascript.md).

## Helpers build tags; they don't format prose

The dominant helper shape is a `*_tag` method that assembles an element with its classes and Stimulus
data attributes. `fizzy/app/helpers/cards_helper.rb:2-19`:

```ruby
  def card_article_tag(card, id: dom_id(card, :article), data: {}, **options, &block)
    classes = [
      options.delete(:class),
      ("golden-effect" if card.golden?),
      ("card--postponed" if card.postponed?),
      ("card--active" if card.active?)
    ].compact.join(" ")

    data[:drag_and_drop_top] = true if card.golden? && !card.closed? && !card.postponed?

    tag.article \
      id: id,
      style: "--card-color: #{card.color}; view-transition-name: #{id}",
      class: classes,
      data: data,
      **options,
      &block
  end
```

Conventions in that one method:
- `tag.article` / `tag.div` / `tag.span` — the `tag` builder, never string interpolation of HTML.
- Array of `("class" if condition)` then `.compact.join(" ")` for conditional classes.
  `fizzy/app/helpers/application_helper.rb:10` uses Rails' `class_names` for the simpler case.
- `**options` passed through and `&block` forwarded, so the helper is a drop-in for `tag.article`.
- `dom_id(card, :article)` as the default id.
- CSS custom properties set inline (`--card-color`) — the bridge between Ruby state and the CSS in
  [`07-css-design.md`](07-css-design.md).

The most elaborate example is `once-campfire/app/helpers/messages_helper.rb:2-23`, which is where all
the Stimulus wiring for the message list lives:

```ruby
  def message_area_tag(room, &)
    tag.div id: "message-area", class: "message-area", contents: true, data: {
      controller: "messages presence drop-target",
      action: [ messages_actions, drop_target_actions, presence_actions ].join(" "),
      messages_first_of_day_class: "message--first-of-day",
      messages_formatted_class: "message--formatted",
      messages_me_class: "message--me",
      messages_mentioned_class: "message--mentioned",
      messages_threaded_class: "message--threaded",
      messages_page_url_value: room_messages_url(room)
    }, &
  end
```

**Rule: when a `data-controller`/`data-action`/`data-*-value` cluster gets long, move the whole element
into a `*_tag` helper.** Templates should not contain twelve data attributes. Note the per-controller
`*_actions` helper methods being joined — each Stimulus controller contributes its own action string,
defined in its own helper.

Small semantic helpers are the other half — `fizzy/app/helpers/application_helper.rb:9-11`:

```ruby
  def icon_tag(name, **options)
    tag.span class: class_names("icon icon--#{name}", options.delete(:class)), "aria-hidden": true, **options
  end
```

One place decides that icons are `aria-hidden`.

## Helper naming and organisation

- One helper module per resource: `cards_helper.rb`, `boards_helper.rb`, `messages_helper.rb`,
  `books_helper.rb`. Rails' default "all helpers everywhere" is left on; the file naming is for humans.
- Cross-cutting concerns get their own file rather than swelling `ApplicationHelper`: fizzy has
  `emoji_helper.rb`, `excerpt_helper.rb`, `forms_helper.rb`, `hotkeys_helper.rb`, `html_helper.rb`,
  `pagination_helper.rb`, `rich_text_helper.rb`, `tenanting_helper.rb`, `time_helper.rb`. `ApplicationHelper`
  itself is 23 lines.
- Helpers can be namespaced in directories: `fizzy/app/helpers/my/`,
  `once-campfire/app/helpers/messages/`, `rooms/`, `users/`, `content_filters/`,
  `writebook/app/helpers/books/`.
- Method names say what they return: `*_tag` returns an element, `*_path`/`*_url` a URL, bare nouns a
  string (`card_drafted_or_added`, `message_timestamp`).

## Wrapping `form_with` to attach behaviour

`writebook/app/helpers/forms_helper.rb:1-7`, in full:

```ruby
module FormsHelper
  def auto_submit_form_with(**attributes, &)
    data = attributes.delete(:data) || {}
    data[:controller] = "auto-submit #{data[:controller]}".strip

    form_with **attributes, data: data, &
  end
end
```

The same helper exists in `fizzy/app/helpers/forms_helper.rb:2-11` and campfire's. Note it *merges*
into any `data[:controller]` the caller passed rather than overwriting — that pattern repeats in
`fizzy/app/helpers/forms_helper.rb:13-30` (`bridged_form_with`), which appends both controllers and
actions:

```ruby
  def bridged_form_with(**attributes, &)
    data = attributes.delete(:data) || {}
    controllers = [ data[:controller], "bridge--form" ].compact.join(" ").strip
    actions = [
      data[:action],
      "turbo:submit-start->bridge--form#submitStart",
      "turbo:submit-end->bridge--form#submitEnd"
    ].compact.join(" ").strip
```

**Rule: to attach standard behaviour to a family of forms, wrap `form_with` in a helper that appends to
`data`, never replaces it.**

## Extending Turbo Streams with a custom action

`writebook/app/helpers/turbo_stream_actions_helper.rb:1-7`, in full:

```ruby
module TurboStreamActionsHelper
  def scroll_into_view(id, animation: nil)
    turbo_stream_action_tag :scroll_into_view, target: id, animation: animation
  end
end

Turbo::Streams::TagBuilder.prepend TurboStreamActionsHelper
```

Seven lines to add `turbo_stream.scroll_into_view(...)` to the vocabulary, paired with a
`Turbo.StreamActions` registration on the JS side. The `prepend` at file scope is deliberate — the
module is loaded for its side effect.

## Layouts: a skeleton of yields and renders

`fizzy/app/views/layouts/application.html.erb:1-42`:

```erb
<!DOCTYPE html>
<html lang="en">
  <%= render "layouts/shared/head" %>

  <body class="<%= @body_class %>"
    data-controller="local-time timezone-cookie turbo-navigation theme bridge--title bridge--text-size bridge--insets"
    data-action="turbo:morph@window->local-time#refreshAll turbo:before-visit@document->turbo-navigation#rememberLocation"
    data-turbo-navigation-label-value="<%= @page_title %>"
    data-platform="<%= platform.type %>"
    data-bridge-platform="<%= platform.bridge_name %>"
    data-bridge-components="<%= platform.bridge_components %>"
    data-bridge--title-title-value="<%= @page_title %>">
    <div id="global-container" data-controller="bridge--buttons bridge--overflow-menu">
      <header class="header header--mobile-actions-stack <%= @header_class %>" id="header">
        <a href="#main" class="header__skip-navigation btn" data-turbo="false">Skip to main content</a>
        <%= render "my/menu" if Current.user %>
        <%= yield :header %>
      </header>

      <%= render "layouts/shared/flash" %>
      <%= render "layouts/shared/time_zone" if Current.user %>

      <main id="main">
        <%= yield %>
      </main>
    </div>
```

- `<head>` is its own partial (`layouts/shared/head`).
- Page-level customisation comes through instance variables assigned by the view
  (`@body_class`, `@header_class`, `@page_title`) and `yield :header` / `yield :footer`.
- App-wide Stimulus controllers are attached to `<body>`.
- The skip link is the first focusable element, with `data-turbo="false"`.
- Multiple layouts per app: fizzy has `application`, `public`, `mailer`. A controller opts in with
  `layout "public"` (`fizzy/app/controllers/sessions_controller.rb:8`).

Views set their own title and chrome — `writebook/app/views/books/index.html.erb:1-4`:

```erb
<% content_for(:title) { "Library | Writebook" } %>
<% @layout_class = "books" %>

<% content_for :header do %>
```

## Flash is a Turbo Frame

`fizzy/app/views/layouts/shared/_flash.html.erb:1-8`:

```erb
<%= turbo_frame_tag :flash do %>
  <% if notice = flash[:notice] || flash[:alert] %>
    <div class="flash" data-controller="element-removal" data-action="animationend->element-removal#remove">
      <div class="flash__inner shadow">
        <%= notice %>
      </div>
    </div>
  <% end %>
<% end %>
```

Wrapped in a frame so a Turbo Stream can target it, and self-removing via a CSS animation end event
rather than a JS timer. Note the assignment-in-condition idiom from
[`02-ruby-style.md`](02-ruby-style.md) inside ERB.

## Sanitising and escaping stay in helpers

`fizzy/app/helpers/html_helper.rb:1-11`:

```ruby
module HtmlHelper
  def format_html(html)
    Loofah::HTML5::DocumentFragment.parse(html).scrub!(AutoLinkScrubber.new).to_html.html_safe
  end

  def card_html_title(card)
    return card.title if card.title.blank?

    ERB::Util.html_escape(card.title).gsub(/`([^`]+)`/, '<code>\1</code>').html_safe
  end
end
```

`html_safe` appears only after an explicit escape or scrub — `ERB::Util.html_escape(...)` first, then
the transformation, then `html_safe`. Never `html_safe` on raw user input.

`writebook/app/helpers/application_helper.rb:2-8` is the one place a `<style>` element is generated,
and it interpolates only an integer id:

```ruby
  def hide_from_user_style_tag
    tag.style(<<~CSS.html_safe)
      [data-hide-from-user-id="#{Current.user.id}"] {
        display: none!important;
      }
    CSS
  end
```

## Rendering failure is contained, not fatal

`once-campfire/app/helpers/messages_helper.rb:42-47`:

```ruby
  rescue Exception => e
    Sentry.capture_exception(e, extra: { message: message })
    Rails.logger.error "Exception while rendering message #{message.class.name}##{message.id}, failed with: #{e.class} `#{e.message}`"

    render "messages/unrenderable"
  end
```

A method-level `rescue` in the helper that builds each message: one corrupt record renders as
"unrenderable" instead of 500ing the whole room. **Rule: in a long user-generated list, isolate
per-item render failures** — and note that it reports (Sentry + log) rather than swallowing.

## JSON is jbuilder, in the same view directory

`fizzy/app/views/cards/` contains `show.json.jbuilder`, `index.json.jbuilder`, `_card.json.jbuilder`
next to the HTML templates, and the controller just renders the format
(`fizzy/app/controllers/cards_controller.rb:38-41`):

```ruby
    respond_to do |format|
      format.turbo_stream
      format.json { render :show }
    end
```

No serializer classes, no `as_json` overrides on models.

## Tests assert against the body, and use `_path`

From `writebook/AGENTS.md`:

> ### URL Helpers in Tests
> Use `_path` helpers instead of `_url` helpers in controller/integration tests unless you need to test
> across different hosts or explicitly need the full URL.
>
> ### Response Body Assertions
> Use `assert_in_body` and `assert_not_in_body` to check if text is present or absent in the response
> body without DOM manipulation.

See [`11-testing.md`](11-testing.md).

## Related

- [`06-hotwire-javascript.md`](06-hotwire-javascript.md) — the `data-controller` attributes these
  templates and helpers emit.
- [`07-css-design.md`](07-css-design.md) — the class naming (`card__header`, `card--postponed`) and the
  custom properties set inline here.
- [`04-controllers-routing.md`](04-controllers-routing.md) — what the controller hands to the view.
- [`20-performance-operability.md`](20-performance-operability.md) — cache-store and HTTP-freshness policy.
