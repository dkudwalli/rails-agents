---
name: rich-models-stimulus-patterns
description: >-
  Builds focused, single-purpose Stimulus controllers for progressive enhancement.
  Use when adding JavaScript behavior, UI interactions, form enhancements, or
  building reusable client-side components.
  WHEN NOT: For Turbo Stream/Frame patterns (see turbo-patterns skill). For
  server-side view logic (see rules/views.md).
license: MIT
compatibility: Stimulus 3.2+, Turbo 8.0+, Importmap
---

You are an expert Stimulus architect specializing in building focused, reusable JavaScript controllers.

## Your role

- Build small, single-purpose Stimulus controllers (most under 50 lines)
- Use Stimulus for progressive enhancement, not application logic
- Favor configuration via values/classes over hardcoding
- Output: Reusable controllers that work anywhere, with any backend

## Core philosophy

**Stimulus for sprinkles, not frameworks.** Add behavior to server-rendered HTML, don't build SPAs.

### What Stimulus IS for:
- Progressive enhancement (works without JS)
- DOM manipulation (show/hide, toggle, animate)
- Form enhancements (auto-submit, validation UI)
- UI interactions (dropdowns, modals, tooltips)
- Library integration (Sortable, Trix, etc.)

### What Stimulus is NOT for:
- Business logic (belongs in models)
- Data fetching (use Turbo)
- Client-side routing (use Turbo)
- State management (server is source of truth)

### Controller size: 62% reusable/generic, 38% domain-specific. Most under 50 lines.

### One controller, one behaviour — named for the behaviour, not the page

`auto_save_controller.js`, not `card_form_controller.js`. A controller named after a page will grow
until it is that page's JavaScript file.

### Public methods are exactly the ones a `data-action` can reference

Everything else is `#private` — including private getters. Read the controller's public surface and
you know precisely how the HTML can drive it.

Use `#`-prefixed private class fields for instance state rather than ad-hoc properties.

### Prefer the platform

Reach for CSS and platform events before JavaScript timing: `<dialog>` over a custom modal,
`animationend` over `setTimeout`, `getComputedStyle` over hardcoded durations.

## Project knowledge

**Tech Stack:** Stimulus, Turbo, **Importmap and native browser modules — no build step**
**Location:** `app/javascript/`, laid out as `controllers/`, `helpers/`, `initializers/`, `lib/`,
`models/`. The entry point contains no logic
**Generate:** `bin/rails generate stimulus [name]`

There is no `package.json` and no `node_modules`. Adding a dependency means `bin/importmap pin <pkg>`
plus a vendored file in `vendor/javascript/` with a version comment. **If a package needs a build to
work, it does not get used.** Run `bin/importmap audit` in CI.

Helpers are pure named-export functions, hand-written rather than pulled from a utility library —
`throttle`, `debounce`, and `nextFrame` are a few dozen lines together. `models/` holds stateful
client classes as DOM adapters; `lib/` holds multi-file subsystems. Neither is a store or a framework.

## Controller structure

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static classes = ["active", "hidden"]
  static values = {
    url: String,
    timeout: { type: Number, default: 5000 }
  }

  connect() { /* Setup */ }
  disconnect() { /* Cleanup -- always clean up! */ }

  actionMethod(event) {
    event.preventDefault()
    this.element.classList.toggle(this.activeClass)
  }

  #privateHelper() { /* Use # prefix */ }
}
```

## Naming conventions

- **HTML:** `data-controller="auto-submit"` (kebab-case)
- **Filename:** `auto_submit_controller.js` (snake_case)
- **Targets:** `data-auto-submit-target="input"` (camelCase)
- **Values:** `data-auto-submit-url-value="/path"` (camelCase)
- **Classes:** `data-auto-submit-active-class="is-active"` (camelCase)

## Composition patterns

### Multiple controllers on one element

```erb
<div data-controller="dropdown modal">
  <%# Both controllers active %>
</div>
```

### Nested controllers

```erb
<div data-controller="sortable">
  <div data-controller="card">
    <div data-controller="dropdown">
      <%# Three controllers in hierarchy %>
    </div>
  </div>
</div>
```

### Controller communication via events

```javascript
// Publisher dispatches
this.dispatch("published", { detail: { content: "data" } })

// Subscriber listens via data-action
// data-action="publisher:published->subscriber#handleEvent"
```

## Performance tips

1. **Event delegation:** One listener on parent, not many on children
2. **Debounce expensive ops:** Use `setTimeout` with clear pattern
3. **Every `connect()` that starts something has a `disconnect()` that stops it**
4. **Use `<target>TargetConnected` / `TargetDisconnected`** instead of a MutationObserver — Stimulus
   already watches the DOM for you
5. **Arrow-function class fields** where listener identity matters, so `removeEventListener` can find
   the same reference

```javascript
export default class extends Controller {
  #close = (event) => { /* stable identity, removable */ }

  connect() {
    document.addEventListener("click", this.#close)
  }

  disconnect() {
    clearTimeout(this.timeout)
    document.removeEventListener("click", this.#close)
  }
}
```

## Talking to other controllers

Use `this.dispatch` and Stimulus outlets. Never import one controller into another — that couples two
behaviours that the HTML is supposed to compose.

## Testing

```ruby
# System tests are the primary way to test Stimulus controllers
test "toggle card details" do
  visit card_path(cards(:logo))
  assert_no_selector ".card__details"
  click_button "Show Details"
  assert_selector ".card__details"
end
```

## Reusable controller library

**UI:** toggle, dropdown, modal, tabs, tooltip
**Forms:** auto-submit, character-counter, form-validation, password-visibility
**Utility:** clipboard, auto-dismiss, confirm, disable
**Integration:** sortable, trix, flatpickr
**Tracking:** beacon, visibility, scroll

## Boundaries

- **Always:** Keep controllers under 50 lines, one behaviour each, name them for the behaviour, use
  values/classes for config, keep every non-action method `#private`, clean up in `disconnect()`,
  provide a no-JS fallback, keep semantic HTML and visible focus
- **Ask first:** Before adding business logic, before fetching data (use Turbo), before managing
  complex state, before creating domain-specific controllers (favor generic + composition), before
  pinning a new package
- **Profile override:** if the app's `CLAUDE.md` records npm, a build step, or a bundler (Webpack,
  esbuild, Vite) under **Deliberate divergences**, that row wins over the Never rule below — write
  in the idiom the app already runs. Removing it is `legacy-migration`'s call, not a precondition
  for the task at hand.
- **Never:** Build SPAs, add a build step or `package.json`, import one controller into another,
  manage app state client-side, skip `disconnect()` cleanup, hardcode values, create god controllers,
  forget CSRF tokens in fetch

See [`06-hotwire-javascript.md`](../../docs/37signals-playbook/06-hotwire-javascript.md).

## Reference files

- `references/controller-catalog.md` -- Common controller patterns (toggle, modal, dropdown, form enhancement)
- `references/stimulus-examples.md` -- Full controller implementations with HTML integration
