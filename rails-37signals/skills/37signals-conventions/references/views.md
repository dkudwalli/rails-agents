---
paths:
  - "app/views/**/*.erb"
  - "app/helpers/**/*.rb"
  - "app/javascript/**/*.js"
---

# View & Frontend Conventions (37signals)

Plain ERB, small partials, and helpers that build tags. No presenters, no view models, no
ViewComponent, no template language other than ERB.

> If the application's `CLAUDE.md` records ViewComponent, presenters, or another template language
> under **Deliberate divergences**, that row wins over this file — build views the way the app
> already builds them.

- **Partials are small and numerous** — 18–29 lines is the observed mean. A 300-line template is a
  structural violation: concepts that deserved names did not get them
- A template's job is to name and order its children. Pass locals explicitly; nest partial
  directories to mirror composition
- **Instance variables are the contract with the view.** No presenter or view model wraps them
- **Helpers build tags, they don't format prose.** Use Rails' `tag` builder, pass through
  `**options` and `&block` so the helper is a drop-in for `tag.article`. Move long
  `data-controller`/`data-action` clusters into helpers
- One helper module per resource; cross-cutting files instead of a swollen `ApplicationHelper`
- `render collection:, cached: true` with `cache record` inside the partial, and `touch: true` on the
  association so outer dolls expire. Add every non-record input to the cache key
- JSON is jbuilder in the same view directory. **No serializer classes, no `as_json` overrides**
- Layouts are skeletons of yields and renders. `html_safe` only after an explicit escape or scrub

## Hotwire and JavaScript

- **No build step.** Importmap plus native browser modules; no `package.json`, no `node_modules`, no
  transpiler. Third-party code is vendored into `vendor/javascript/` with a version comment. If a
  package needs a build to work, it does not get used. Propshaft serves assets
- No React, Vue, or Alpine. The server is the source of truth; there is no client-side store or router
- Prefer `broadcasts_refreshes` with page morphing over hand-written broadcasts; `method: :morph` on
  replaces. Turbo Frames for independently-updating regions
- One Stimulus controller per behaviour, named for the behaviour, not the page
- **Public methods are exactly the ones a `data-action` can reference. Everything else is `#private`**
- Use targets and values; private fields for instance state. Every `connect()` that starts something
  has a matching `disconnect()`
- `<target>TargetConnected/Disconnected` instead of MutationObservers; `this.dispatch` and outlets
  instead of importing other controllers
- Prefer CSS and platform events (`<dialog>`, `animationend`, `getComputedStyle`) over JS timing
- Helpers are pure named-export functions, hand-written rather than pulled from a utility library
- Action Text for rich text; Active Storage for uploads — see `skills/content-storage`

See [`05-views-helpers.md`](../../../docs/37signals-playbook/05-views-helpers.md) and
[`06-hotwire-javascript.md`](../../../docs/37signals-playbook/06-hotwire-javascript.md).
