# 06 — Hotwire & JavaScript

There is no build step, no `package.json` in any of the three applications, and no `node_modules`.
JavaScript is ES modules served directly to the browser via importmap, and the total is small: 4,182
lines in fizzy, 3,956 in campfire, 1,095 in writebook.

---

## No bundler, no transpiler, no npm

`fizzy/config/importmap.rb:1-20`:

```ruby
# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/turbo/offline", to: "turbo-offline.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@hotwired/hotwire-native-bridge", to: "@hotwired--hotwire-native-bridge.js"
pin "@rails/request.js", to: "@rails--request.js" # @0.0.13

pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/helpers", under: "helpers"
pin_all_from "app/javascript/lib", under: "lib"
pin_all_from "app/javascript/initializers", under: "initializers"
```

Third-party packages are vendored into `vendor/javascript/` by `bin/importmap`; the version is recorded
in a trailing comment. Asset serving is Propshaft (all three).

**Rules:**
- `pin_all_from` per directory, so a new file is importable with no config change.
- Absolute-ish import paths matching the pin names: `import { signedDifferenceInDays } from "helpers/date_helpers"`.
- Adding a dependency means `bin/importmap pin <pkg>` and a vendored file you can read. If the package
  needs a build to work, it doesn't get used.
- `bin/importmap audit` runs in CI (`fizzy/config/ci.rb`).

## JavaScript directory layout

```
app/javascript/
  application.js       entry point: imports only
  controllers/         Stimulus controllers, one per behaviour
    application.js     the Stimulus Application instance
    index.js           eager loader
  helpers/             pure functions, exported individually
  initializers/        code that runs once on load, for its side effects
  lib/                 multi-file subsystems
  models/              stateful client-side classes (campfire only)
  actions/             custom Turbo Stream actions (writebook only)
```

`writebook/app/javascript/application.js:1-5` is the whole entry point:

```javascript
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "actions"
import "controllers"
import "house"
```

`fizzy/app/javascript/application.js`:

```javascript
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@hotwired/hotwire-native-bridge"
import "initializers"
import "controllers"

import "lexxy"
import "@rails/actiontext"
import "lib/action_pack/passkey"
```

The entry point contains no logic. Directories expose an `index.js` that imports their members —
`fizzy/app/javascript/initializers/index.js:1-4`:

```javascript
import "initializers/current"
import "initializers/bridge/bridge_element"
import "initializers/offline"
import "initializers/lexxy_markdown_paste"
```

Controllers are **eager** loaded, unchanged from the Rails default
(`writebook/app/javascript/controllers/index.js:1-11`, identical in fizzy).

---

## Stimulus conventions

### One behaviour per controller, and the controller is small

fizzy has 89 JS files for 4,182 lines. Controller names describe a behaviour, not a page or a model:
`auto_submit`, `autoresize`, `element_removal`, `local_time`, `morph_guard`, `scroll_to`,
`soft_keyboard`, `upload_preview`, `copy_to_clipboard`, `web_share`, `toggle_class`,
`fetch_on_visible`, `maintain_scroll`.

The smallest is a complete, useful controller —
`fizzy/app/javascript/controllers/element_removal_controller.js:1-7`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
```

Used from a template as `data-action="animationend->element-removal#remove"`
(`fizzy/app/views/layouts/shared/_flash.html.erb:3`). Behaviour-named controllers get reused across
unrelated features; page-named ones don't.

### `export default class extends Controller` — anonymous

Every controller in all three apps is an anonymous default export. The filename is the identifier;
there is no class name to keep in sync.

### Private methods with `#`, and the public surface is only actions

`fizzy/app/javascript/controllers/auto_submit_controller.js:1-43`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:submit-end", this.#handleSubmitEnd.bind(this), { once: true })
    this.submit()
  }

  submit() {
    this.#markAsBusy()
    this.#disableSubmit()
    this.element.requestSubmit()
  }

  #handleSubmitEnd(event) {
    if (event.detail.success) {
      this.element.remove()
    } else {
      this.#clearBusy()
      this.#enableSubmit()
    }
  }

  #markAsBusy() {
    this.element.setAttribute("aria-busy", "true")
  }

  #clearBusy() {
    this.element.setAttribute("aria-busy", "false")
  }

  #disableSubmit() {
    this.#submitElements().forEach(element => element.disabled = true)
  }

  #enableSubmit() {
    this.#submitElements().forEach(element => element.disabled = false)
  }

  #submitElements() {
    return this.element.querySelectorAll("input[type=submit],button")
  }
}
```

**Rules visible here:**
- Public methods are exactly the ones a `data-action` can reference (`submit`). Everything else is
  `#private`.
- Private *getters* too — `get #isClickable()`
  (`writebook/app/javascript/controllers/hotkey_controller.js:14`), `get #hasEntropy()`
  (`fizzy/app/javascript/controllers/bubble_controller.js:31`).
- Tiny well-named private methods over inline logic: `#markAsBusy()` wraps a single
  `setAttribute`. This is the same "invocation order / intention-revealing names" discipline as the Ruby
  in [`02-ruby-style.md`](02-ruby-style.md).
- `aria-busy` and `disabled` are set as part of the behaviour — accessibility is in the controller, not
  bolted on.

### Private fields for instance state

`fizzy/app/javascript/controllers/bubble_controller.js:4-19`:

```javascript
const REFRESH_INTERVAL = 3_600_000 // 1 hour (in milliseconds)

export default class extends Controller {
  static targets = [ "entropy", "stalled", "top", "center", "bottom" ]
  static values = { entropy: Object, stalled: Object }

  #timer

  connect() {
    this.#timer = setInterval(this.update.bind(this), REFRESH_INTERVAL)
    this.update()
  }

  disconnect() {
    clearInterval(this.#timer)
  }
```

Module-level `const` for tuning numbers, with numeric separators (`3_600_000`) and a unit comment.
`#timer` as a private field. **Every `connect()` that starts something has a `disconnect()` that stops
it** — timers, listeners, observers.

### `static targets` / `static values`, spaced array literals

```javascript
  static targets = [ "caption", "image", "dialog", "zoomedImage" ]
  static values = { entropy: Object, stalled: Object }
```

Note `[ "a", "b" ]` with inner spaces — the same whitespace convention as `%i[ ]` in Ruby.

### Target lifecycle callbacks instead of manual queries

`fizzy/app/javascript/controllers/lightbox_controller.js:6-17`:

```javascript
  imageTargetConnected(element) {
    element.addEventListener("click", this.#handleImageClick)
  }

  imageTargetDisconnected(element) {
    element.removeEventListener("click", this.#handleImageClick)
  }

  #handleImageClick = (event) => {
    event.preventDefault()
    this.#open(event.currentTarget)
  }
```

`<target>TargetConnected` / `Disconnected` handles elements that arrive later via Turbo — no
`MutationObserver`, no re-scanning. The handler is an arrow-function **class field** so `this` is bound
once and `removeEventListener` gets the same reference. (Contrast
`auto_submit_controller.js:5`, which uses `.bind(this)` with `{ once: true }` where identity doesn't
matter.)

### `this.dispatch` to talk to other controllers

`fizzy/app/javascript/controllers/lightbox_controller.js:34` — `this.dispatch('closed')` emits
`lightbox:closed`, which another element listens for with a `data-action`. Controllers communicate
through DOM events and Stimulus outlets (`reply_composer_outlet: "#composer"` in
`once-campfire/app/helpers/messages_helper.rb:40`), not by importing each other.

### Prefer CSS and platform events over JS timing

- `<dialog>` and `showModal()` for modals (`lightbox_controller.js:20`), not a JS overlay.
- `animationend` / `transitionend` drive removal and reset
  (`lightbox_controller.js:25-29`, `_flash.html.erb:3`), instead of `setTimeout` matched to a CSS
  duration.
- `getComputedStyle(this.element).pointerEvents !== "none"` to ask whether an element is interactive
  (`writebook/app/javascript/controllers/hotkey_controller.js:15`) — CSS is the source of truth.
- Guard against acting inside inputs: `event.defaultPrevented || event.target.closest("input, textarea")`
  (`hotkey_controller.js:11`).

---

## Helpers: pure functions, individually exported

`writebook/app/javascript/helpers/timing_helpers.js:1-39` — the whole timing toolkit, hand-written
rather than imported from lodash:

```javascript
export function throttle(fn, delay = 1000) {
  let timeoutId = null

  return (...args) => {
    if (!timeoutId) {
      fn(...args)
      timeoutId = setTimeout(() => timeoutId = null, delay)
    }
  }
}

export function debounce(fn, delay = 1000) {
  let timeoutId = null

  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => fn.apply(this, args), delay)
  }
}

export function nextEventLoopTick() {
  return delay(0)
}

export function nextFrame() {
  return new Promise(requestAnimationFrame)
}

export function nextEventNamed(eventName, element = window) {
  return new Promise(resolve => element.addEventListener(eventName, resolve, { once: true }))
}

export function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}
```

Files are grouped by subject: `date_helpers`, `form_helpers`, `html_helpers`, `meta_helpers`,
`orientation_helpers`, `platform_helpers`, `scroll_helpers`, `text_helpers`, `timing_helpers`,
`cookie_helpers`, `reading_progress_helpers`. Named exports only; no default export from a helper
module.

Module-private functions are simply not exported —
`fizzy/app/javascript/helpers/date_helpers.js:23-52` keeps `datePartsInTimezone`, `dateFormatter` and
`buildDateFormatter` internal, with a module-level memo:

```javascript
let dateFormatterCache
let dateFormatterTimezone

function dateFormatter() {
  const timezone = getMetaContent("timezone")

  if (!dateFormatterCache || dateFormatterTimezone !== timezone) {
    dateFormatterTimezone = timezone
    dateFormatterCache = buildDateFormatter(timezone)
  }

  return dateFormatterCache
}
```

and degrades rather than throwing on a bad timezone (`date_helpers.js:47-51`):

```javascript
  try {
    return new Intl.DateTimeFormat("en-US", { ...options, timeZone: timezone })
  } catch {
    return new Intl.DateTimeFormat("en-US", options)
  }
```

The comment above it (`date_helpers.js:20-22`) explains *why* the server's timezone is used instead of
the browser's — exactly the kind of comment [`02-ruby-style.md`](02-ruby-style.md) calls for:

```javascript
// Snap a timestamp to midnight using the timezone the server rendered with (the
// `timezone` meta tag), so client day boundaries match the server's instead of
// following the browser's resolved timezone, which can differ in a PWA.
```

## `models/` for stateful client-side objects

Campfire is the only one of the three with enough client state to need it —
`once-campfire/app/javascript/models/` holds `client_message.js`, `file_uploader.js`,
`message_formatter.js`, `message_paginator.js`, `scroll_manager.js`, `typing_tracker.js`. These are
plain classes, imported by the controllers that own them.

**Rule: when a Stimulus controller grows a data structure or an algorithm, extract it to
`app/javascript/models/` and keep the controller as the DOM adapter.** Not a store, not a framework —
one class per concept, mirroring how `app/models/` works on the server.

## `lib/` for vendored or multi-file subsystems

`fizzy/app/javascript/lib/action_pack/passkey` (WebAuthn wiring),
`once-campfire/app/javascript/lib/autocomplete/` and `lib/rich_text/`, plus a single-purpose
`lib/cookie.js`.

---

## Turbo

### Refreshes broadcast from the model, morphing applies them

`fizzy/app/models/card/broadcastable.rb:1-18`, in full:

```ruby
module Card::Broadcastable
  extend ActiveSupport::Concern

  included do
    broadcasts_refreshes

    before_update :remember_if_preview_changed
  end

  private
    def remember_if_preview_changed
      @preview_changed ||= title_changed? || column_id_changed? || board_id_changed?
    end

    def preview_changed?
      @preview_changed
    end
end
```

`broadcasts_refreshes` sends a "something changed" signal; the client re-requests the page and Turbo
morphs the DOM. No per-attribute stream templates, no manual `broadcast_replace_to` for ordinary
updates.

**Rule: prefer `broadcasts_refreshes` + morphing over hand-written broadcast calls.** Reach for explicit
streams only when you need to target one element in one user's page — as
`once-campfire/app/controllers/rooms/involvements_controller.rb:16-25` does:

```ruby
    def broadcast_visibility_changes
      case
      when @room.direct?
        # Do nothing
      when @membership.involved_in_invisible?
        broadcast_remove_to @membership.user, :rooms, target: [ @room, :list ]
      when @membership.involvement_previously_was.inquiry.invisible?
        broadcast_prepend_to @membership.user, :rooms, target: :shared_rooms, partial: "users/sidebars/rooms/shared", locals: { room: @room }
      end
    end
```

### `method: :morph` on replaces

`fizzy/app/views/cards/update.turbo_stream.erb:2` and
`fizzy/app/controllers/concerns/card_scoped.rb:18`:

```ruby
      render turbo_stream: turbo_stream.replace([ @card, :card_container ], partial: "cards/container", method: :morph, locals: { card: @card.reload })
```

Morphing preserves focus, scroll position and open `<details>`. There is a `morph_guard_controller.js`
in fizzy for the elements that must *not* be morphed.

### Custom Stream actions when the vocabulary is short

JS side, `writebook/app/javascript/actions/scroll_into_view.js:1-16`:

```javascript
import { Turbo } from "@hotwired/turbo-rails"

Turbo.StreamActions.scroll_into_view = function() {
  const animation = this.getAttribute("animation")
  const element = this.targetElements[0]

  element.scrollIntoView({ behavior: "smooth", block: "center" })

  if (animation) {
    element.addEventListener("animationend", () => {
      element.classList.remove(animation)
    }, { once: true })

    element.classList.add(animation)
  }
}
```

Ruby side is the seven-line helper in [`05-views-helpers.md`](05-views-helpers.md)
(`writebook/app/helpers/turbo_stream_actions_helper.rb`). Two small files add a first-class stream verb.

### Frames for independently-updating regions

`turbo_frame_tag :flash` (`fizzy/app/views/layouts/shared/_flash.html.erb:1`), and per-record frames
around editable content — `once-campfire/app/views/messages/_message.html.erb:11`:

```erb
    <turbo-frame id="<%= dom_id(message, :edit) %>">
```

`data-turbo-permanent` marks elements that must survive navigation
(`fizzy/app/views/layouts/application.html.erb:32`):

```erb
        <div id="footer_frames" data-turbo-permanent="true">
```

### Wiring lives in helpers, not templates

See [`05-views-helpers.md`](05-views-helpers.md) — long `data-controller` / `data-action` /
`data-*-value` clusters are moved into `*_tag` helpers. The layout is the exception, since its
controllers are app-wide (`fizzy/app/views/layouts/application.html.erb:6-12`).

## PWA and native, without a second codebase

- Service worker and manifest are rendered by Rails: `get "manifest" => "rails/pwa#manifest"` and
  `get "service-worker" => "pwa#service_worker"` (`fizzy/config/routes.rb`), with
  `fizzy/app/views/pwa/service_worker.js.erb` as an ERB template.
- Web Push via the `web-push` gem in all three, subscriptions stored as `Push::Subscription` records.
- Native apps share the web views through Hotwire Native: `@hotwired/hotwire-native-bridge` in the
  importmap, `app/javascript/bridge/` controllers, and a `platform` object exposed to views
  (`fizzy/app/views/layouts/application.html.erb:9-12`) so templates can vary by platform. There is no
  separate mobile frontend.

## Related

- [`05-views-helpers.md`](05-views-helpers.md) — where `data-controller` attributes are generated.
- [`07-css-design.md`](07-css-design.md) — why so much behaviour is CSS instead of JS.
- [`03-models.md`](03-models.md) — `broadcasts_refreshes` as a model concern.
- [`17-realtime-notifications.md`](17-realtime-notifications.md) — when to use a Turbo broadcast versus a custom Cable protocol.
