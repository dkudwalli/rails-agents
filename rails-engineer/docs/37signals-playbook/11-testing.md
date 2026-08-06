# 11 — Testing

Minitest and fixtures. No RSpec, no FactoryBot, no `shoulda`, no `let`, no `describe`, no shared
examples.

| repo | test files | fixture files | tests |
|---|---|---|---|
| fizzy | 253 | 32 | 1,555 |
| once-campfire | 61 | 11 | 301 |
| writebook | 37 | 11 | 181 |

---

## `test/` mirrors `app/`, plus a few extras

```
fizzy/test/
  channels/  controllers/  helpers/  integration/  jobs/  lib/  mailers/
  middleware/  models/  system/
  fixtures/
  test_helpers/                     shared assertions and setup, as concerns
  application_system_test_case.rb
  test_helper.rb
  routes_test.rb                    the routes file has its own test
  setup-phases-test                 an executable that tests bin/setup
```

No `spec/`, no `support/`, no `factories/`.

## `ApplicationSystemTestCase` and `test_helper.rb` are the only global setup

`writebook/test/test_helper.rb:1-15`, in full — this is the baseline all three start from:

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include SessionTestHelper
  end
end
```

Three decisions: parallel by default, **all fixtures loaded for every test**, and shared helpers pulled
in as modules.

`once-campfire/test/test_helper.rb:12-37` adds the pieces that need resetting between tests:

```ruby
class ActiveSupport::TestCase
  include ActiveJob::TestHelper

  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  include SessionTestHelper, MentionTestHelper, TurboTestHelper

  setup do
    ActionCable.server.pubsub.clear

    Rails.configuration.tap do |config|
      config.x.web_push_pool.shutdown
      config.x.web_push_pool = WebPush::Pool.new \
        invalid_subscription_handler: config.x.web_push_pool.invalid_subscription_handler
    end

    WebMock.disable_net_connect!
  end

  teardown do
    WebMock.reset!
  end
end
```

**Rule: global `setup`/`teardown` is for resetting process-level state** (pubsub, connection pools,
HTTP stubs) — not for building test data. Data comes from fixtures.

Fizzy's adds tenancy and job-context discipline (`fizzy/test/test_helper.rb:56-72`):

```ruby
    # Jobs must carry their own account context via AccountTenanted,
    # not rely on Current.account leaking from the test setup.
    def perform_enqueued_jobs(...)
      saved_account = Current.account
      Current.account = nil
      super
    ensure
      Current.account = saved_account
    end

    setup do
      Current.account = accounts("37s")
    end

    teardown do
      Current.clear_all
    end
```

`perform_enqueued_jobs` is overridden to **blank the ambient account** so a job that forgot to
serialize its context fails in the test suite instead of production. That is a test harness enforcing a
production invariant — see `AccountTenanted` in [`08-jobs-async.md`](08-jobs-async.md).

## Fixtures, not factories

`writebook/test/fixtures/books.yml`, the whole file:

```yaml
handbook:
  title: Handbook
  slug: handbook

manual:
  title: Manual
  slug: manual
```

Fixtures are minimal, named after their role in tests (`handbook` vs `manual` — one accessible, one
not), and 11 files cover the whole app.

`writebook/AGENTS.md` states the rule:

> ### Use Existing Fixtures
> Prefer using existing fixtures over creating new records in tests. For example, use
> `leaves(:welcome_page)` instead of `books(:handbook).press Page.new(body: "..."), title: "..."`.

**Rules:**
- Reach for a fixture first. Add a new fixture only when no existing one can express the case.
- Mutate a fixture in the test when you need a variant: `books(:manual).update!(published: true)`
  (`writebook/test/controllers/books_controller_test.rb:17`). Cheaper to read than a factory with
  overrides, and the baseline stays visible.
- Fixture names are domain words, not `user_1` / `user_2`.

### Deterministic fixture UUIDs (fizzy)

Fixtures normally get ids from `crc32(label)`, which breaks when the primary key is a UUID: ordering
becomes random, so `.first` / `.last` are meaningless in tests.
`fizzy/test/test_helper.rb:99-129` fixes it:

```ruby
module FixturesTestHelper
  extend ActiveSupport::Concern

  class_methods do
    def identify(label, column_type = :integer)
      if label.to_s.end_with?("_uuid")
        column_type = :uuid
        label = label.to_s.delete_suffix("_uuid")
      end

      # Rails passes :string for varchar columns, so handle both :uuid and :string
      return super(label, column_type) unless column_type.in?([ :uuid, :string ])
      generate_fixture_uuid(label)
    end

    private

    def generate_fixture_uuid(label)
      # Generate deterministic UUIDv7 for fixtures that sorts by fixture ID
      # This allows .first/.last to work as expected in tests
      # Use the same CRC32 algorithm as Rails' default fixture ID generation
      # so that UUIDs sort in the same order as integer IDs
      fixture_int = Zlib.crc32("fixtures/#{label}") % (2**30 - 1)

      # Translate the deterministic order into times in the past, so that records
      # created during test runs are also always newer than the fixtures.
      base_time = Time.utc(2024, 1, 1, 0, 0, 0)
      timestamp = base_time + (fixture_int / 1000.0)

      uuid_v7_with_timestamp(timestamp, label)
    end
```

installed with (`fizzy/test/test_helper.rb:178-180`):

```ruby
ActiveSupport.on_load(:active_record_fixture_set) do
  prepend(FixturesTestHelper)
end
```

Two properties deliberately engineered: fixtures sort in the same order as the integer scheme would,
**and** every fixture timestamp is in the past so records created during a test are always newer. If
you adopt UUID keys, you need this.

## Test naming and structure

`writebook/test/models/leaf_test.rb:1-13`, in full:

```ruby
require "test_helper"

class LeafTest < ActiveSupport::TestCase
  test "slug is generated from title" do
    assert_equal "hello-world", Leaf.new(title: "Hello, World!").slug
  end

  test "slug is never completely blank" do
    assert_equal "-", Leaf.new(title: "").slug
  end
end
```

- `test "…"` with a sentence describing the behaviour, not `def test_slug`.
- One assertion per test where possible; no `describe`/`context` nesting.
- No arrange/act/assert comments, no blank-line ceremony for a two-line test.

## Controller tests are integration tests, and they test the response

`writebook/test/controllers/books_controller_test.rb:1-42`:

```ruby
require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :kevin
  end

  test "index lists the current user's books" do
    get root_url

    assert_response :success
    assert_select "h2", text: "Handbook"
    assert_select "h2", text: "Manual", count: 0
  end

  test "index includes published books, even when the user does not have access" do
    books(:manual).update!(published: true)

    get root_url

    assert_response :success
    assert_select "h2", text: "Handbook"
    assert_select "h2", text: "Manual"
  end

  test "index shows published books when not logged in" do
    books(:manual).update!(published: true)

    sign_out
    get root_url

    assert_response :success
    assert_select "h2", text: "Handbook", count: 0
    assert_select "h2", text: "Manual"
  end

  test "index redirects to login if not signed in and no published books exist" do
    sign_out
    get root_url

    assert_redirected_to new_session_url
  end
```

**Rules:**
- `ActionDispatch::IntegrationTest`, not `ActionController::TestCase`. Real requests through the full
  stack.
- **Test the visible outcome**, not the assigns: `assert_select`, `assert_response`,
  `assert_redirected_to`. There are no `assert_equal @controller.instance_variable_get(...)` tests.
- **Assert the negative too** — `count: 0` on the book the user shouldn't see. Authorization tests are
  as important as the happy path, and the four tests above cover signed-in, published-but-inaccessible,
  signed-out, and no-access-at-all.
- Auth in `setup` via a helper, one line.

### `assert_in_body` for text without DOM parsing

From `writebook/AGENTS.md`:

> ### Response Body Assertions
> Use `assert_in_body` and `assert_not_in_body` to check if text is present or absent in the response
> body without DOM manipulation.
>
> **Preferred:**
> ```ruby
> assert_in_body "Expected content"
> assert_not_in_body "Unexpected content"
> ```
>
> **Avoid:**
> ```ruby
> assert_includes response.body, "Expected content"
> assert_not_includes response.body, "Unexpected content"
> ```

Used for non-HTML responses where `assert_select` doesn't apply, e.g. Markdown
(`writebook/test/controllers/leafables_controller_test.rb:54-56`):

```ruby
    assert_in_body "## Hello"
    assert_in_body "This is **bold** text."
    assert_in_body "title: \"Welcome to The Handbook!\""
```

### `_path` over `_url` in request tests

Also from `writebook/AGENTS.md`:

> Use `_path` helpers instead of `_url` helpers in controller/integration tests unless you need to test
> across different hosts or explicitly need the full URL.
>
> **Preferred:**
> ```ruby
> get book_slug_path(books(:handbook))
> ```

(The older tests in that same repo still use `_url` — the guidance is newer than the code, which is
itself a useful signal about which to follow.)

## Assert the state change, not the mechanism

`fizzy/test/controllers/cards/closures_controller_test.rb:1-35`:

```ruby
require "test_helper"

class Cards::ClosuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "create" do
    card = cards(:logo)

    assert_changes -> { card.reload.closed? }, from: false, to: true do
      post card_closure_path(card), as: :turbo_stream
      assert_card_container_rerendered(card)
    end
  end

  test "destroy" do
    card = cards(:shipping)

    assert_changes -> { card.reload.closed? }, from: true, to: false do
      delete card_closure_path(card), as: :turbo_stream
      assert_card_container_rerendered(card)
    end
  end

  test "create as JSON" do
    card = cards(:logo)

    assert_not card.closed?

    post card_closure_path(card), as: :json

    assert_response :no_content
    assert card.reload.closed?
  end
```

**Rules:**
- `assert_changes -> { … }, from:, to:` with **both** endpoints stated. `assert_difference` for counts
  (`assert_difference -> { Book.count }, +1 do`,
  `writebook/test/controllers/books_controller_test.rb:45`).
- `as: :turbo_stream` / `as: :json` to exercise each format the controller declares. If an action has a
  `respond_to` with two formats, there are two tests.
- Fixtures are chosen to already be in the right starting state — `cards(:logo)` is open,
  `cards(:shipping)` is closed — so the test doesn't set up before it acts.
- `card.reload` before asserting on a record the request touched.

## Shared assertions become `test_helpers/` concerns

`fizzy/test/test_helpers/card_test_helper.rb:1-5`, in full:

```ruby
module CardTestHelper
  def assert_card_container_rerendered(card)
    assert_turbo_stream action: :replace, target: dom_id(card, :card_container)
  end
end
```

One custom assertion, named for the domain event, wrapping the mechanical check. That's why the
controller tests above read as behaviour.

`writebook/test/test_helpers/session_test_helper.rb:1-16`, in full:

```ruby
module SessionTestHelper
  def parsed_cookies
    ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
  end

  def sign_in(user)
    user = users(user) unless user.is_a? User
    post session_url, params: { email_address: user.email_address, password: "secret123456" }
    assert cookies[:session_token].present?
  end

  def sign_out
    delete session_url
    assert_not cookies[:session_token].present?
  end
end
```

Three details to copy:

- **`sign_in` authenticates through the real endpoint**, not by stubbing `Current.user`. If login breaks,
  every test fails — which is correct.
- **It accepts a symbol or a record** (`user = users(user) unless user.is_a? User`), so tests read
  `sign_in :kevin`.
- **The helper asserts its own postcondition.** A helper that silently fails to sign in would produce
  baffling failures downstream.

fizzy's helper set is larger and each file is one subject: `action_text_test_helper.rb`,
`caching_test_helper.rb`, `card_activity_test_helper.rb`, `card_test_helper.rb`,
`change_test_helper.rb`, `command_test_helper.rb`, `dns_test_helper.rb`, `search_test_helper.rb`,
`session_test_helper.rb`, `vcr_test_helper.rb`, `webauthn_test_helper.rb`. They're included on
`ActiveSupport::TestCase` in one line (`fizzy/test/test_helper.rb:53`):

```ruby
    include ActionTextTestHelper, CachingTestHelper, CardTestHelper, ChangeTestHelper, DnsTestHelper, SessionTestHelper
```

**Rule: when an assertion appears in three tests, give it a name in a `*TestHelper` module.**

## System tests: few, real browser, and driver config is explicit

`writebook/test/application_system_test_case.rb:1-7`, in full:

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SystemTestHelper

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
end
```

Campfire has three system tests — `boosting_messages_test.rb`, `sending_messages_test.rb`,
`unread_rooms_test.rb`. They cover the interactions that genuinely need a browser (Turbo Streams
arriving, unread state updating), not CRUD that an integration test already covers.

Fizzy's version documents each Chrome flag it needs
(`fizzy/test/application_system_test_case.rb:4-30`):

```ruby
  browser_options = Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument("--window-size=1200,800")
    opts.add_argument("--disable-extensions")
    # Disable non-foreground tabs from getting a lower process priority
    opts.add_argument("--disable-renderer-backgrounding")
    # Normally, Chrome will treat a 'foreground' tab instead as backgrounded if the surrounding
    # window is occluded (aka visually covered) by another window. This flag disables that.
    opts.add_argument("--disable-backgrounding-occluded-windows")
    # Suppress all permission prompts by automatically denying them.
    opts.add_argument("--deny-permission-prompts")
    opts.add_argument("--enable-automation")
  end

  Capybara.register_driver :chrome_headless do |app|
    browser_options.add_argument("--headless")
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
  end

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
  end

  if ENV["SYSTEM_TESTS_BROWSER"]
    driven_by :chrome, screen_size: [ 1200, 1000 ]
  else
    driven_by :chrome_headless, screen_size: [ 1200, 1000 ]
  end
```

Every non-obvious flag has a comment saying which flake it prevents. `SYSTEM_TESTS_BROWSER` runs
headed for debugging. And the app-specific interaction glue is a private method rather than repeated
Capybara calls (`fizzy/test/application_system_test_case.rb:32-42`):

```ruby
  private
    def sign_in_as(user)
      visit session_transfer_url(user.identity.transfer_id, script_name: nil)
      assert_current_path root_path
    end

    def fill_in_lexxy(selector = "lexxy-editor", with:)
      editor_element = find(selector)
      editor_element.set with
      page.execute_script("arguments[0].value = '#{with}'", editor_element)
    end
```

**System tests run serially** — `fizzy/config/ci.rb`:

```ruby
SYSTEM_TEST_ENV = "PARALLEL_WORKERS=1" # system tests can't run reliably in parallel
```

as a separate CI step from the unit run.

## Parallelism, and work stealing

`fizzy/test/test_helper.rb:47`:

```ruby
    parallelize workers: :number_of_processors, work_stealing: ENV["WORK_STEALING"] != "false"
```

Campfire and writebook use plain `parallelize(workers: :number_of_processors)`. **Rule: run parallel
from day one** — it forces test isolation early, when fixing it is cheap.

Also note the URL-scoping setup that multi-tenancy requires
(`fizzy/test/test_helper.rb:76-79`):

```ruby
class ActionDispatch::IntegrationTest
  setup do
    integration_session.default_url_options[:script_name] = "/#{ActiveRecord::FixtureSet.identify("37signals")}"
  end
```

## External HTTP: stubbed by default, recorded when it matters

Campfire disables all outbound HTTP in `setup` and resets in `teardown`
(`once-campfire/test/test_helper.rb:31-36`) — a test that forgets to stub fails loudly.

Fizzy uses WebMock plus VCR cassettes, with two refinements worth copying
(`fizzy/test/test_helper.rb:18-43`):

```ruby
VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<OPEN_AI_KEY>") { Rails.application.credentials.openai_api_key || ENV["OPEN_AI_API_KEY"] }
  config.default_cassette_options = {
    match_requests_on: [ :method, :uri, :body ]
  }

  # Ignore timestamps in request bodies
  config.before_record do |i|
    if i.request&.body
      i.request.body.gsub!(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/, "<TIME>")
    end
  end

  config.register_request_matcher :body_without_times do |r1, r2|
    b1 = (r1.body || "").gsub(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/, "<TIME>")
    b2 = (r2.body || "").gsub(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC/, "<TIME>")
    b1 == b2
  end
```

- **`filter_sensitive_data`** so recorded cassettes never contain a key.
- **A custom matcher that normalises timestamps**, so cassettes don't go stale the moment a request body
  includes `Time.current`.

## Mocking is available but rare

`mocha` is in fizzy's and campfire's `Gemfile`; writebook has no mocking library at all. The default is
real objects and fixtures. Test doubles are reached for at process boundaries (mailers, HTTP, push),
not to isolate one model from another.

## What else gets a test

- **`routes_test.rb`** — the routing table itself is asserted (fizzy).
- **`test/middleware/`** — the tenancy extractor middleware.
- **`test/helpers/`** — view helpers, directly.
- **`test/jobs/`** — with `ActiveJob::TestHelper` and the account-context guard described above.
- **`test/setup-phases-test`** — an executable that verifies `bin/setup` works from a clean checkout.
  The onboarding script is tested like code, because it is.

## Related

- [`09-data-search.md`](09-data-search.md) — the UUID scheme that makes fixture ids non-trivial.
- [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md) — how these suites are run in CI.
- [`04-controllers-routing.md`](04-controllers-routing.md) — the controllers these tests exercise.
