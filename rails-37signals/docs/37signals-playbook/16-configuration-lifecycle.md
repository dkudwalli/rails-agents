# 16 — Configuration & request lifecycle

Configuration is executable product code. Keep the global baseline in `config/application.rb`, use an
environment file for runtime policy, and keep every initializer narrow enough to explain why it
exists.

Rails context: [Configuring Rails Applications](https://guides.rubyonrails.org/configuring.html)
explains the framework lifecycle and configuration locations. The rules below come from the apps.

---

## Set one Rails baseline, then override by environment

All three applications use `config/application.rb` for defaults and `config/environments/production.rb`
for production policy. Do not scatter environment checks through models or controllers.

`fizzy/config/application.rb:8-33`:

```ruby
module Fizzy
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib ignore: %w[ assets tasks rails_ext ]

    config.after_initialize do
      Rails.event.debug_mode = true
    end

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  end
end
```

**Rules:**

- Put framework-version defaults, generator defaults, and application-wide autoload policy in
  `config/application.rb`.
- Use `config.autoload_lib ignore:` rather than manually requiring application code; ignore only
  directories that are not reloadable Ruby.
- Put runtime choices — caching, storage, logging, TLS, and queue adapter — in the environment file.
- Do not copy another application's `load_defaults` version. Fizzy is on 8.1, Campfire on 8.2
  (`once-campfire/config/application.rb:7-19`), and Writebook on 7.2
  (`writebook/config/application.rb:9-29`). Follow the Rails version actually running.

## Keep initializers narrow and lifecycle-aware

An initializer names one framework extension or deployment-level concern. Defer work that depends
on loaded application classes to `after_initialize`, `to_prepare`, or the relevant Active Support
load hook.

`fizzy/config/initializers/multi_tenant.rb:1-4`:

```ruby
Rails.application.configure do
  config.after_initialize do
    Account.multi_tenant = ENV["MULTI_TENANT"] == "true" || config.x.multi_tenant.enabled == true
  end
end
```

`fizzy/lib/rails_ext/active_storage_authorization.rb:21-31` uses `to_prepare` to install a concern
on Rails controllers, so development reloads do not leave it stale.

**Rules:**

- Make an initializer's filename and first comment name its one responsibility.
- Use a framework load hook when extending a Rails class; do not rely on load order.
- Use `after_initialize` only for work that requires loaded models or configured engines.
- Put deployment switches at the configuration boundary, backed by a safe default; do not have
  business code consult `ENV` repeatedly.
- Explain custom framework code in comments, including why Rails does not already provide it.

## Establish request context at the edge

`Current` is request-scoped context, not a second persistence layer. Fizzy captures request metadata
in a controller concern and lets assignment derive related domain context:

`fizzy/app/controllers/concerns/current_request.rb:1-12`:

```ruby
module CurrentRequest
  extend ActiveSupport::Concern

  included do
    before_action do
      Current.http_method = request.method
      Current.request_id  = request.uuid
      Current.user_agent  = request.user_agent
      Current.ip_address  = request.ip
      Current.referrer    = request.referrer
    end
  end
end
```

`fizzy/app/models/current.rb:1-27` keeps the complete list of attributes and derives `identity` and
`user` from session/account assignment.

**Rules:**

- Populate request data once at the request boundary; controllers and models read it but do not
  rebuild it.
- Keep every `Current` attribute explicit and derive only closely related values.
- Clear or serialize `Current` when crossing a job or Cable boundary; see
  [`08-jobs-async.md`](08-jobs-async.md) and [`17-realtime-notifications.md`](17-realtime-notifications.md).
- Do not use `Current` for data that must survive a request. Persist that on a model.

## Production policy is explicit and boring

Fizzy enables production caching, eager loading, a real queue adapter, and structured stdout logging
in one file (`fizzy/config/environments/production.rb:35-103`). Campfire does the same baseline and
also silences the health-check path (`once-campfire/config/environments/production.rb:7-95`):

```ruby
config.enable_reloading = false
config.eager_load = true
config.consider_all_requests_local       = false
config.action_controller.perform_caching = true
config.logger = ActiveSupport::Logger.new(STDOUT)
  .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
  .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
config.log_tags = [ :request_id ]
```

**Rules:**

- In production, disable reloading, eager-load, hide detailed errors, enable caching, and log to
  stdout with a request id.
- Configure HTTPS at the reverse-proxy boundary and make any local/dev bypass explicit.
- Select one queue/cache/storage backend per environment; do not leave a production default to
  incidental development behavior.
- Filter secrets, tokens, credentials, and personal identifiers centrally
  (`fizzy/config/initializers/filter_parameter_logging.rb:1-8`).
- Add error-report context lazily, so it is useful without adding request work in the happy path
  (`fizzy/config/initializers/error_context.rb:1-7`).

## Configuration is an interface

Fizzy derives both mailer and route URL options from one `BASE_URL` at boot
(`fizzy/config/environments/production.rb:24-33`) and selects local storage unless an explicit
`ACTIVE_STORAGE_SERVICE` overrides it (`production.rb:57-61`). Treat these names as documented
deployment inputs, with safe local defaults and secrets outside Git.

Do not add generic `config.x` settings for values with one caller. Add a named configuration input
when a deployer, not a Ruby caller, must choose the value.

## Related

- [`10-auth-security.md`](10-auth-security.md) — request protection and security headers.
- [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md) — deployment-provided environment values.
- [`20-performance-operability.md`](20-performance-operability.md) — logging, caching, and health checks.
