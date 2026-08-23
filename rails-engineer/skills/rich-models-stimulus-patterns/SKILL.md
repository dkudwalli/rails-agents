---
name: rich-models-stimulus-patterns
description: >-
  Builds focused, single-purpose Stimulus controllers for progressive enhancement.
  Use when adding JavaScript behavior, UI interactions, form enhancements, or
  building reusable client-side components.
  Applies only in a rich-models profile app.
  WHEN NOT: A layered profile app — use layered-stimulus-patterns. For Turbo Stream/Frame patterns (see rails-frontend). For
  server-side view logic (see [views reference](../37signals-conventions/references/views.md)).
compatibility: Stimulus 3.2+, Turbo 8.0+, Importmap
---

# Stimulus Patterns (37signals)

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

## No build step

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

## References

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`controller-structure.md`](references/controller-structure.md) | Targets, values, classes, lifecycle, and the naming conventions |
| [`composition.md`](references/composition.md) | Multiple and nested controllers, events, outlets |
| [`controller-catalog.md`](references/controller-catalog.md) | UI, form, and utility controllers — toggle, dropdown, modal, tabs, tooltip, auto-submit, character-counter, form validation, clipboard, auto-dismiss, confirm, disable |
| [`stimulus-examples.md`](references/stimulus-examples.md) | Full implementations with HTML — integration (sortable, trix, flatpickr), tracking, animation, domain-specific |
| [`performance-and-testing.md`](references/performance-and-testing.md) | Event delegation, cleanup, listener identity, system tests |

## Boundaries

- **Always:** Keep controllers under 50 lines, one behaviour each, name them for the behaviour, use
  values/classes for config, keep every non-action method `#private`, clean up in `disconnect()`,
  provide a no-JS fallback, keep semantic HTML and visible focus
- **Ask first:** Before adding business logic, before fetching data (use Turbo), before managing
  complex state, before creating domain-specific controllers (favor generic + composition), before
  pinning a new package
- **Profile override:** if the app's `AGENTS.md` records npm, a build step, or a bundler (Webpack,
  esbuild, Vite) under **Deliberate divergences**, that row wins over the Never rule below — write
  in the idiom the app already runs. Removing it is `rich-models-legacy-migration`'s call, not a precondition
  for the task at hand.
- **Never:** Build SPAs, add a build step or `package.json`, import one controller into another,
  manage app state client-side, skip `disconnect()` cleanup, hardcode values, create god controllers,
  forget CSRF tokens in fetch

Rules live in `37signals-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.

See [`06-hotwire-javascript.md`](../../docs/37signals-playbook/06-hotwire-javascript.md).
