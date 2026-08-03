# 10 — Authentication, authorization & security

No Devise, no Pundit, no CanCan, no OmniAuth. Authentication is a `Session` record and a signed cookie;
authorization is scoping plus a few predicate methods. Roughly 100 lines of code per app.

---

## Session is a record; the cookie holds a token

`writebook/app/models/session.rb:1-19` and `once-campfire/app/models/session.rb:1-19` are byte-identical:

```ruby
class Session < ApplicationRecord
  ACTIVITY_REFRESH_RATE = 1.hour

  has_secure_token

  belongs_to :user

  before_create { self.last_active_at ||= Time.now }

  def self.start!(user_agent:, ip_address:)
    create! user_agent: user_agent, ip_address: ip_address
  end

  def resume(user_agent:, ip_address:)
    if last_active_at.before?(ACTIVITY_REFRESH_RATE.ago)
      update! user_agent: user_agent, ip_address: ip_address, last_active_at: Time.now
    end
  end
end
```

`fizzy/app/models/session.rb:1-3` is smaller still, because sessions belong to a global identity rather
than an account-scoped user:

```ruby
class Session < ApplicationRecord
  belongs_to :identity
end
```

**Why a record and not a cookie payload:** the user can list and revoke their sessions, you get device
and IP history for free, and signing out is a `DELETE`. `resume` throttles writes to once an hour so
every request isn't an `UPDATE`.

The cookie, `once-campfire/app/controllers/concerns/authentication.rb:86-88`:

```ruby
    def set_authentication_cookie(session)
      cookies.signed.permanent[:session_token] = { value: session.token, httponly: true, same_site: :lax }
    end
```

`signed` (tamper-proof), `permanent`, `httponly`, `same_site: :lax`. Fizzy uses `session.signed_id`
instead of a stored token (`fizzy/app/controllers/concerns/authentication.rb:104`).

Lookup is its own tiny concern so Action Cable can share it —
`writebook/app/controllers/concerns/authentication/session_lookup.rb:1-7`, in full:

```ruby
module Authentication::SessionLookup
  def find_session_by_cookie
    if token = cookies.signed[:session_token]
      Session.find_by(token: token)
    end
  end
end
```

used by both `authentication.rb:34` and `app/channels/application_cable/connection.rb:13`.

## The `Authentication` concern, and its class macros

`writebook/app/controllers/concerns/authentication.rb:1-46`:

```ruby
module Authentication
  extend ActiveSupport::Concern
  include SessionLookup

  included do
    before_action :require_authentication
    helper_method :signed_in?

    protect_from_forgery with: :exception, unless: -> { authenticated_by.bot_key? }
  end

  class_methods do
    def require_unauthenticated_access(**options)
      allow_unauthenticated_access **options
      before_action :redirect_signed_in_user_to_root, **options
    end

    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      before_action :restore_authentication, **options
    end
  end

  private
    def signed_in?
      Current.user.present?
    end

    def require_authentication
      restore_authentication || request_authentication
    end

    def restore_authentication
      if session = find_session_by_cookie
        resume_session session
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_url
    end
```

**Rules:**

- **Secure by default.** `before_action :require_authentication` is unconditional in
  `ApplicationController`; individual controllers *opt out* with `allow_unauthenticated_access`. A new
  controller is protected because you did nothing.
- **The opt-out is a named macro, not a `skip_before_action` call at the call site.** That gives one
  place to add the accompanying behaviour: `allow_unauthenticated_access` also runs
  `restore_authentication`, so a public page still knows who you are.
- **`require_unauthenticated_access` is a distinct macro** for sign-in pages, adding the
  "already signed in → go home" redirect.
- **`require_authentication` is a chain of alternatives**: `restore_authentication || request_authentication`.
  Campfire's adds bot auth in the middle (`once-campfire/app/controllers/concerns/authentication.rb:33-35`):
  ```ruby
      def require_authentication
        restore_authentication || bot_authentication || request_authentication
      end
  ```
  and fizzy's adds bearer tokens (`fizzy/app/controllers/concerns/authentication.rb:44-46`):
  ```ruby
      def require_authentication
        resume_session || authenticate_by_bearer_token || request_authentication
      end
  ```
  New credential types are new `||` branches, each its own private method.
- **`return_to_after_authenticating` in the session**, consumed once after login
  (`post_authenticating_url` / `after_authentication_url`).
- `helper_method :signed_in?` so views can ask without touching `Current` directly.

### Track how the request authenticated

`once-campfire/app/controllers/concerns/authentication.rb:94-104`:

```ruby
    def deny_bots
      head :forbidden if authenticated_by.bot_key?
    end

    def set_authenticated_by(method)
      @authenticated_by = method.to_s.inquiry
    end

    def authenticated_by
      @authenticated_by ||= "".inquiry
    end
```

`.inquiry` (see [`02-ruby-style.md`](02-ruby-style.md)) makes `authenticated_by.bot_key?` read well,
and the credential type then drives two policies:

- **CSRF is skipped only for bot-key requests** — `protect_from_forgery with: :exception, unless: -> { authenticated_by.bot_key? }`
  (`authentication.rb:10`). Not skipped per-controller, not globally.
- **Bots are denied everywhere by default** (`before_action :deny_bots`, `authentication.rb:7`) and
  allowed per-controller with `allow_bot_access`.

Fizzy applies the same idea to bearer tokens (`fizzy/app/controllers/concerns/authentication.rb:58-74`):

```ruby
    def authenticate_by_bearer_token
      if request.authorization.to_s.include?("Bearer")
        if bearer_token_authenticatable_request?
          authenticate_or_request_with_http_token do |token|
            if identity = Identity.find_by_permissable_access_token(token, method: request.method)
              Current.identity = identity
            end
          end
        else
          request_http_token_authentication
        end
      end
    end

    def bearer_token_authenticatable_request?
      request.format.json?
    end
```

Tokens work only on JSON requests — an API credential can't be used to drive the HTML UI.

**Rule: record which credential authenticated the request, and gate CSRF, rate limits and capabilities
on that rather than on the controller.**

## Authorization is scoping, with predicates for the rest

`writebook/app/models/concerns/authorization.rb:1-10`, in full:

```ruby
module Authorization
  private
    def ensure_can_administer
      head :forbidden unless Current.user.can_administer?
    end

    def ensure_current_user
      head :forbidden unless @user.current?
    end
end
```

`once-campfire/app/controllers/concerns/authorization.rb:1-6` is five lines. That is the entire
authorization *framework* in those apps. Note the file style: a module of only private methods marks
`private` at the top, per `fizzy/STYLE.md:126-136`.

Almost all access control happens in the lookup instead — from
[`04-controllers-routing.md`](04-controllers-routing.md):

```ruby
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])   # card_scoped.rb:10
      @board = Current.user.boards.find(params[:board_id])                       # board_scoped.rb:10
```

An unreachable record 404s. There is no separate "can this user read this?" step to forget.

The predicates live on the model — `fizzy/app/models/user/role.rb:1-32`:

```ruby
module User::Role
  extend ActiveSupport::Concern

  included do
    enum :role, %i[ owner admin member system ].index_by(&:itself), scopes: false

    scope :owner, -> { where(active: true, role: :owner) }
    scope :admin, -> { where(active: true, role: %i[ owner admin ]) }
    scope :member, -> { where(active: true, role: :member) }
    scope :active, -> { where(active: true, role: %i[ owner admin member ]) }

    def admin?
      super || owner?
    end
  end

  def can_change?(other)
    (admin? && !other.owner?) || other == self
  end

  def can_administer?(other)
    admin? && !other.owner? && other != self
  end

  def can_administer_board?(board)
    admin? || board.creator == self
  end

  def can_administer_card?(card)
    admin? || card.creator == self
  end
end
```

**Rules:**
- Roles are a string enum with `scopes: false`, and the scopes are written by hand so they can also
  require `active: true` — an inactive owner is not an owner.
- `def admin?; super || owner?; end` — override the enum predicate so "admin" includes "owner" once,
  globally, instead of writing `admin? || owner?` at 40 call sites.
- Capability predicates are named `can_<verb>_<noun>?` and live on `User`. The controller's
  `before_action` is a one-line `head :forbidden unless …`.
- The rules encode the awkward cases explicitly: an admin cannot administer an owner, and cannot
  administer themselves.

A fourth role, `system`, exists for machine actors and is deliberately excluded from the `active` scope.

## Fizzy's account layer: authorization *and* tenancy

`fizzy/app/controllers/concerns/authorization.rb:1-44`:

```ruby
module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :ensure_can_access_account, if: :authenticated_account_access?
  end

  class_methods do
    def allow_unauthorized_access(**options)
      skip_before_action :ensure_can_access_account, **options
    end

    def require_access_without_a_user(**options)
      skip_before_action :ensure_can_access_account, **options
      before_action :redirect_existing_user, **options
    end
  end

  private
    def ensure_admin
      head :forbidden unless Current.user.admin?
    end

    def ensure_staff
      head :forbidden unless Current.identity.staff?
    end

    def authenticated_account_access?
      Current.account.present? && authenticated?
    end

    def ensure_can_access_account
      unless Current.account.active? && Current.user&.active?
        respond_to do |format|
          format.html { redirect_to session_menu_path(script_name: nil) }
          format.json { head :forbidden }
        end
      end
    end
```

Both the **account** and the **user** must be active — a cancelled account locks out even a valid
session. And `require_account` runs before `require_authentication`, with a comment saying why
(`fizzy/app/controllers/concerns/authentication.rb:5`):

```ruby
    before_action :require_account # Checking and setting account must happen first
```

**Rule: in a multi-tenant app, resolve the tenant before authenticating, and check tenant status
alongside user status.**

## Identity vs User (fizzy's model, worth understanding)

`fizzy/app/models/identity.rb:1-40`:

```ruby
class Identity < ApplicationRecord
  include Joinable, Transferable

  has_passkeys name: :email_address, display_name: -> { Current.user&.name || email_address }

  has_many :access_tokens, dependent: :destroy
  has_many :magic_links, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :users, dependent: :nullify
  has_many :accounts, through: :users

  has_one_attached :avatar, dependent: :purge_later

  before_destroy :deactivate_users, prepend: true

  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email_address, with: ->(value) { value.strip.downcase.presence }
```

An `Identity` is one email address globally; a `User` is that identity's membership of one account.
Credentials (sessions, passkeys, magic links, access tokens) hang off `Identity`; roles and content hang
off `User`.

Details worth copying regardless of tenancy:

- **`normalizes :email_address, with: ->(value) { value.strip.downcase.presence }`** — normalisation is
  declared on the model, so no controller ever has to remember to downcase.
- **`validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }`** — the stdlib regexp, not a
  hand-rolled one.
- **`before_destroy :deactivate_users, prepend: true`** — `prepend` so it runs before
  `dependent:` teardown.
- **`has_many :users, dependent: :nullify`** — deleting an identity keeps the account's content and
  history, orphaning the membership instead of cascading.

## Passwordless: magic links

`fizzy/app/models/magic_link.rb:1-43`:

```ruby
class MagicLink < ApplicationRecord
  CODE_LENGTH = 6
  EXPIRATION_TIME = 15.minutes

  belongs_to :identity

  enum :purpose, %w[ sign_in sign_up ], prefix: :for, default: :sign_in

  scope :active, -> { where(expires_at: Time.current...) }
  scope :stale, -> { where(expires_at: ..Time.current) }

  before_validation :generate_code, on: :create
  before_validation :set_expiration, on: :create

  validates :code, uniqueness: true, presence: true

  class << self
    def consume(code)
      active.find_by(code: Code.sanitize(code))&.consume
    end

    def cleanup
      stale.delete_all
    end
  end

  def consume
    destroy
    self
  end

  private
    def generate_code
      self.code ||= loop do
        candidate = Code.generate(CODE_LENGTH)
        break candidate unless self.class.exists?(code: candidate)
      end
    end

    def set_expiration
      self.expires_at ||= EXPIRATION_TIME.from_now
    end
end
```

Security properties, each in one line:

- **Single use** — `consume` destroys the record and returns `self`, so a replayed code finds nothing.
- **Expiry as a beginless/endless range** — `where(expires_at: Time.current...)` for active,
  `..Time.current` for stale. The lookup in `consume` goes through `active`, so an expired code is
  simply not found.
- **Uniqueness enforced twice** — a validation plus a generation loop that retries on collision.
- **`cleanup` for the recurring schedule** (see [`08-jobs-async.md`](08-jobs-async.md)); stale links
  don't linger.
- **Input sanitised before lookup** — `Code.sanitize(code)` (`fizzy/app/models/magic_link/code.rb`)
  normalises what the user typed.

### Don't leak whether an account exists

`fizzy/app/controllers/sessions_controller.rb:14-22`:

```ruby
  def create
    if identity = Identity.find_by(email_address: email_address)
      sign_in identity
    elsif Account.accepting_signups?
      sign_up
    else
      redirect_to_fake_session_magic_link email_address
    end
  end
```

The unknown-email branch generates a **fake** magic link so the response is indistinguishable —
`fizzy/app/controllers/concerns/authentication/via_magic_link.rb:15-23`:

```ruby
    def redirect_to_fake_session_magic_link(email_address, **options)
      fake_magic_link = MagicLink.new(
        identity: Identity.new(email_address: email_address),
        code: SecureRandom.base32(6),
        expires_at: MagicLink::EXPIRATION_TIME.from_now
      )

      redirect_to_session_magic_link fake_magic_link, **options
    end
```

Unsaved records, so nothing is written. **Rule: enumeration resistance means the same response shape,
not a different error message.**

### A guard against a development convenience escaping

`fizzy/app/controllers/concerns/authentication/via_magic_link.rb:4-13`:

```ruby
  included do
    after_action :ensure_development_magic_link_not_leaked
  end

  private
    def ensure_development_magic_link_not_leaked
      unless Rails.env.development?
        raise "Leaking magic link via flash in #{Rails.env}?" if flash[:magic_link_code].present?
      end
    end
```

Development shows the code in the flash so you don't need email. An `after_action` **raises** in any
other environment if that flash is present. **Rule: when you add a development-only shortcut around
auth, add a runtime assertion that it cannot fire elsewhere.**

## Passkeys, and API tokens

Passkeys: `has_passkeys name: :email_address, display_name: -> { … }`
(`fizzy/app/models/identity.rb:4`), `include ActionPack::Passkey::Request` in the controller
(`fizzy/app/controllers/sessions_controller.rb:2`), a `resource :passkey, only: :create` route, and
`resources :passkeys` under `namespace :my`. The authenticator registry is a `Data` class reading a
YAML config (`fizzy/app/models/passkey/authenticator.rb:1-22`):

```ruby
class Passkey::Authenticator < Data.define(:aaguids, :name, :icon)
  class << self
    def find_by_aaguid(aaguid)
      registry[aaguid]
    end
```

with the data in `config/passkey_aaguids.yml` loaded via `Rails.application.config_for`. **Rule: static
reference data belongs in `config/*.yml` + `config_for`, not in a Ruby constant or the database.**

API tokens — `fizzy/app/models/identity/access_token.rb:1-10`, in full:

```ruby
class Identity::AccessToken < ApplicationRecord
  belongs_to :identity

  has_secure_token
  enum :permission, %w[ read write ].index_by(&:itself), default: :read

  def allows?(method)
    method.in?(%w[ GET HEAD ]) || write?
  end
end
```

`has_secure_token` for generation, a two-value permission enum, and one method mapping HTTP verbs to
permissions. Ten lines for scoped API keys. Passwords, where they exist, are
`has_secure_password validations: false` (`once-campfire/app/models/user.rb:20`) — bcrypt via Rails.

## Rate limiting is Rails' own, declared per action

```ruby
  rate_limit to: 10, within: 3.minutes, only: :create, with: :rate_limit_exceeded       # sessions_controller.rb:6
  rate_limit to: 10, within: 15.minutes, only: :create, with: :rate_limit_exceeded      # sessions/magic_links_controller.rb:4
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }  # join_codes_controller.rb:3
  rate_limit to: 5, within: 1.hour, only: :create                                        # users/email_addresses/confirmations_controller.rb:5
```

Every credential-issuing endpoint is limited, with the window matched to the action (an hour for email
confirmations, minutes for sign-in). The `with:` handler responds in both HTML and JSON
(`fizzy/app/controllers/sessions_controller.rb:47-54`).

**Rule: rate-limit anything that sends mail, issues a credential, or accepts a code — at the action,
not in the proxy.**

## Banning at the request boundary

`once-campfire/app/controllers/concerns/block_banned_requests.rb:1-16`, in full:

```ruby
module BlockBannedRequests
  extend ActiveSupport::Concern

  included do
    before_action :reject_banned_ip, unless: :safe_request?
  end

  private
    def reject_banned_ip
      head :too_many_requests if Ban.banned?(request.remote_ip)
    end

    def safe_request?
      request.get? || request.head?
    end
end
```

A `Ban` record (the state-as-record pattern again), enforced only on unsafe verbs so reads stay cheap.

## SSRF protection for user-supplied URLs

Campfire unfurls links and fizzy delivers webhooks, so both fetch URLs the user chose.
`fizzy/app/models/ssrf_protection.rb:1-54` is a `module … extend self` holding the blocklists:

```ruby
module SsrfProtection
  extend self

  DNS_RESOLUTION_TIMEOUT = 2

  DNS_NAMESERVERS = %w[
    1.1.1.1
    8.8.8.8
  ]

  # IPv4 ranges that must never be a fetch target (RFC 5735/6890 special-use,
  # plus CGNAT and benchmarking). RFC1918/loopback/link-local are also covered
  # by the IPAddr predicates in #blocked_address?.
  DISALLOWED_IP_RANGES = [
    IPAddr.new("0.0.0.0/8"),       # "This" network (RFC1700)
    IPAddr.new("10.0.0.0/8"),      # Private (RFC1918)
    IPAddr.new("100.64.0.0/10"),   # Carrier-grade NAT (RFC6598)
    IPAddr.new("127.0.0.0/8"),     # Loopback
    IPAddr.new("169.254.0.0/16"),  # Link-local (incl. AWS metadata)
    ...
```

What makes this a model to copy rather than just a blocklist:

- **Resolve DNS yourself, with a timeout and explicit nameservers**, then check the *resolved address* —
  not the hostname. Checking the hostname is the classic SSRF bypass.
- **Every entry cites its RFC** and says what it is, so nobody deletes a line they don't recognise.
- **IPv6 is handled separately**, including deprecated transition mechanisms
  (`DISALLOWED_IPV6_RANGES`) — and NAT64 prefixes are decoded back to their embedded IPv4 address and
  re-checked (`ssrf_protection.rb:47-54`):
  ```ruby
    # NAT64 prefixes: the well-known prefix (RFC 6052/6146) and the local-use
    # prefix (RFC 8215). An address here embeds an IPv4 target in its low 32
    # bits; extract it and re-check against the IPv4 rules so NAT64 to a public
    # address still resolves while NAT64 to an internal address is blocked.
  ```
- Cloud metadata endpoints are called out by name (`169.254.0.0/16`, and IMDSv6 in the IPv6 comment).

**Rule: any feature that fetches a user-supplied URL needs this. Deny by resolved IP, not by hostname
or scheme.**

## Configuration-level hardening

**Parameter filtering** — `fizzy/config/initializers/filter_parameter_logging.rb:6-8`:

```ruby
Rails.application.config.filter_parameters += %i[
  passw secret token _key crypt salt certificate otp ssn
]
```

Campfire extends it with content and identifiers, not just credentials
(`once-campfire/config/initializers/filter_parameter_logging.rb:6-8`):

```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc, :endpoint, "message.body"
]
```

`:email` and `"message.body"` mean logs contain no user content and no addresses. **Rule: filter
personal data and user content, not only secrets.**

**CSP** is configured, and made deployment-tunable rather than hardcoded —
`fizzy/config/initializers/content_security_policy.rb:6-13`:

```ruby
# Directives are configurable via environment variables with fallback to config.x
# settings. This allows fizzy-saas (or other deployments) to extend the base policy
# without duplicating it.
#
# ENV vars (space-separated sources):
#   CSP_DEFAULT_SRC, CSP_SCRIPT_SRC, CSP_STYLE_SRC, CSP_CONNECT_SRC, CSP_FRAME_SRC,
#   CSP_IMG_SRC, CSP_FONT_SRC, CSP_MEDIA_SRC, CSP_WORKER_SRC, CSP_FRAME_ANCESTORS,
#   CSP_FORM_ACTION, CSP_REPORT_URI, CSP_REPORT_ONLY, DISABLE_CSP
```

Inline scripts carry a nonce (`javascript_tag nonce: true` in
`fizzy/app/views/layouts/_theme_preference.html.erb:1`) and `csp_meta_tag` is in `<head>`
(`fizzy/app/views/layouts/shared/_head.html.erb:12`).

**Browser floor** — `allow_browser versions: :modern` (`fizzy/app/controllers/application_controller.rb:12`,
`writebook/app/controllers/application_controller.rb:5`), which also removes a class of old-browser
attack surface.

**Search-engine blocking** as a concern (`BlockSearchEngineIndexing` in
`fizzy/app/controllers/application_controller.rb:4`) rather than a stray `robots.txt`.

## Security is part of CI, not a periodic audit

From `fizzy/config/ci.rb`:

```ruby
  step "Security: Gem audit", "bin/bundler-audit check --update"
  step "Security: Importmap audit", "bin/importmap audit"
  step "Security: Brakeman audit", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Security: Gitleaks audit", "bin/gitleaks-audit"
```

Four scanners on every run, all `--exit-on-warn`: Ruby dependencies, JavaScript dependencies, static
analysis, and committed secrets. `bin/` wrappers so the invocation is identical locally and in CI.
`prek.toml` adds a `detect-private-key` pre-commit hook. All three apps carry `brakeman` and
`bundler-audit` in their `Gemfile`, plus a Dependabot config.

Brakeman findings are triaged in a checked-in `config/brakeman.ignore` — 6 accepted fingerprints in
fizzy — rather than by disabling the tool.

## Related

- [`04-controllers-routing.md`](04-controllers-routing.md) — the scoped lookups that do most of the
  authorization work.
- [`03-models.md`](03-models.md) — `Current` and how session context propagates.
- [`12-tooling-ci-deploy.md`](12-tooling-ci-deploy.md) — the CI pipeline these steps belong to.
- [`19-integrations-webhooks.md`](19-integrations-webhooks.md) — outbound HTTP, webhook credentials, and delivery boundaries.
