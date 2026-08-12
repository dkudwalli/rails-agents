---
paths:
  - "test/**/*.rb"
  - "test/fixtures/**/*.yml"
---

# Testing Conventions (37signals)

> If the application's `AGENTS.md` records RSpec or FactoryBot under **Deliberate divergences**,
> that row wins over this file — write tests in the framework the suite already uses.

- Minitest and fixtures. No RSpec, no FactoryBot, no shoulda, no `let`, no `describe`, no shared examples
- `test/` mirrors `app/`. There is no `spec/`, no `support/`, no `factories/`
- **Reach for an existing fixture before constructing a record.** Mutate it in the test for a variant:
  `books(:manual).update!(published: true)`. Name fixtures with domain words
- Fixture counts stay small — an entire suite can run on a dozen fixture files
- `test "sentence describing the behaviour" do`. No `describe`/`context` nesting, no AAA comments
- **Global `setup`/`teardown` is for resetting process state, not for building test data.** Test data
  belongs in fixtures or visibly in the test body
- Controller tests are `ActionDispatch::IntegrationTest` asserting visible outcomes — `assert_select`,
  `assert_response`, `assert_redirected_to`, `assert_in_body`. Never `assigns`
- **Assert the negative too**: `assert_select "h2", text: "Manual", count: 0`
- Assert the state change, not the mechanism: `assert_changes -> { ... }, from:, to:` and
  `assert_difference`. Choose a fixture already in the right starting state
- Exercise each declared format: `as: :turbo_stream`, `as: :json`. Prefer `_path` over `_url`
- Shared assertions become `test/test_helpers/` concerns, one subject per file, named for the domain
  event. `sign_in` authenticates through the real endpoint — never by stubbing `Current.user` — and
  asserts its own postcondition
- `parallelize(workers: :number_of_processors)` from day one; it forces test isolation early. Run
  system tests serially
- Few system tests, real browser, every Chrome flag commented with the flake it prevents
- Stub external HTTP by default (WebMock); VCR with `filter_sensitive_data`. Test doubles are for
  process boundaries, not for isolating one model from another
- Routes, middleware, helpers, jobs, and `bin/setup` get tests too
- Add one focused test for new non-trivial logic; do not scaffold a framework around it

> Fizzy profile only: deterministic fixture UUIDs and cross-account isolation tests. These belong
> with UUID primary keys and the account layer as one package — see [migrations.md](migrations.md).

See [`11-testing.md`](../../../docs/37signals-playbook/11-testing.md).
