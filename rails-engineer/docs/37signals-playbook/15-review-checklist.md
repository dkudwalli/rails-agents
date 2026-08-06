# 15 — Rails review checklist

Use this as a PR or agent review pass. It is intentionally a checklist, not a scorecard: a relevant
unchecked item is a reason to ask a question.

## Shape

- [ ] Is the code in a standard Rails location before introducing a new top-level directory?
- [ ] Does a controller call a model API directly rather than route through a default service layer?
- [ ] Is the behaviour already present as a model concern, helper, partial or browser API?
- [ ] Does a new domain transition have a noun and a resource rather than a custom controller verb?
- [ ] Is the diff the smallest complete change, including the migration/index/test needed for its invariant?

See [`01-philosophy.md`](01-philosophy.md), [`03-models.md`](03-models.md), and
[`04-controllers-routing.md`](04-controllers-routing.md).

## Ruby and models

- [ ] Do names explain the domain operation without a comment translating them?
- [ ] Are methods ordered in call order, with private methods below `private`?
- [ ] Is `!` used only when a non-bang counterpart exists?
- [ ] Does a model own persistence, transitions, callbacks and query scopes that belong to it?
- [ ] Are default associations, `Current`, and asynchronous context explicit where needed?
- [ ] Do orderings break timestamp ties with `id`?
- [ ] Does an absolute invariant have a database constraint/index, not only a validation?

See [`02-ruby-style.md`](02-ruby-style.md), [`03-models.md`](03-models.md), and
[`09-data-search.md`](09-data-search.md).

## HTTP, view, and browser

- [ ] Is the new endpoint conventional CRUD, nested only as far as its ownership requires?
- [ ] Does a scoped record lookup enforce authorization by construction?
- [ ] Is unauthenticated access an explicit controller macro rather than an ad-hoc skip?
- [ ] Is a view split into readable partials and does display logic live in a helper when shared?
- [ ] Does a Stimulus controller own one browser behaviour, use targets/values, and keep implementation
  methods private?
- [ ] Is the solution importmap/native HTML/CSS before a JavaScript or CSS build dependency?
- [ ] Does interactive UI retain semantic HTML, keyboard access and visible focus?

See [`04-controllers-routing.md`](04-controllers-routing.md), [`05-views-helpers.md`](05-views-helpers.md),
[`06-hotwire-javascript.md`](06-hotwire-javascript.md), [`07-css-design.md`](07-css-design.md), and
[`10-auth-security.md`](10-auth-security.md).

## Async, data, and operations

- [ ] Is the app's ONCE-compatible or Fizzy profile recorded, with deliberate deviations called out?
- [ ] Does a job delegate the domain operation to a model and use `_later` / `_now` when paired?
- [ ] Does an async job serialize all required tenant/request context rather than leak `Current`?
- [ ] Is one queue/cache/cable family selected rather than accidentally mixing Solid and Redis stacks?
- [ ] Are migrations small, reversible through `change`, and named after one concern?
- [ ] Does search stay in the database unless requirements demonstrably exceed it?
- [ ] Is setup rerunnable, with destructive reset work behind an explicit flag?
- [ ] Does CI run style, security checks and the appropriate serial system tests?
- [ ] Does the production image have a build stage, no baked secrets, and a non-root runtime user?

See [`08-jobs-async.md`](08-jobs-async.md), [`09-data-search.md`](09-data-search.md),
[`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md), and
[`21-new-app-decisions.md`](21-new-app-decisions.md).

## Tests

- [ ] Does the test use an existing fixture before constructing records?
- [ ] Is test setup limited to process state, with data visible in fixtures or the test body?
- [ ] Does it assert user-observable output or the domain boundary, not implementation noise?
- [ ] Does it cover authorization/scoping, the unhappy path, and background behaviour where relevant?
- [ ] Are external HTTP calls controlled with WebMock/VCR only where they truly cross the boundary?
- [ ] If new non-trivial logic was added, is there one small test that fails when it breaks?

See [`11-testing.md`](11-testing.md).
