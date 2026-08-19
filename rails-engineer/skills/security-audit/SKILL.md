---
name: security-audit
description: >-
  Audits Rails application security against OWASP Top 10, detects
  vulnerabilities with Brakeman, and verifies the profile-selected authorization model.
  Use when the user wants a security audit, vulnerability scan, or when user
  mentions security, OWASP, Brakeman, XSS, SQL injection, or authorization.
  WHEN NOT: Implementing security fixes (use rails-guide),
  setting up authentication (use rails-access), or implementing authorization
  rules (use rails-access).
user-invocable: true
argument-hint: "[file or directory path]"
---

# Security Audit

## Profile routing

Read the target application's `AGENTS.md` and its Rails Engineer Profile before auditing. If the
profile is absent, use `rails-onboard` and stop. Use `rails-access` to select authentication and
authorization checks, `rails-testing` to select the test command, and `rails-architecture` to
select application paths. In particular:

- `Authorization: pundit` — inspect policies, scopes, and `authorize` coverage.
- `Authorization: scoped-model` — inspect account-scoped finders, membership checks, and the
  authorization reference selected by `rails-access`; do not require Pundit.
- `Testing: rspec` runs the relevant policy/request specs. `Testing: minitest` runs the relevant
  policy/controller/integration tests with `bin/rails test`.
- A layered app may have services, queries, forms, and policies. A rich-models app may keep the
  same behavior in models, concerns, controllers, and scoped associations. Audit the paths that
  exist for the selected architecture.

You NEVER modify credentials, secrets, or production files.

## Audit Process

### Step 1: Run Security Tools

```bash
bin/brakeman
bin/bundler-audit check --update
# Then run the profile-selected focused test command from rails-testing.
```

### Step 2: Manual Code Review

Audit `app/controllers/`, `app/models/`, `app/views/`, and `config/`, plus the selected
architecture's existing domain paths. Include `app/policies/` only when the authorization profile
or a recorded divergence uses policies.

### Step 3: Report Findings

Format: **Vulnerability** → **Location** (file:line) → **Risk** → **Fix** (code example)
Prioritize: P0 (critical) → P1 (high) → P2 (medium) → P3 (low)

Read the `behavioral-guidelines` skill § Reporting Rules and apply it to the report — in
particular, omit sections where nothing was found rather than listing every clean check.

## OWASP Top 10 — Rails Patterns

### 1. Injection (SQL, Command)
```ruby
# Bad — SQL Injection
User.where("email = '#{params[:email]}'")

# Good — Bound parameters
User.where(email: params[:email])
```

### 2. Broken Authentication
```ruby
# Bad — Predictable token
user.update(reset_token: SecureRandom.hex(4))

# Good — Sufficiently long token
user.update(reset_token: SecureRandom.urlsafe_base64(32))
```

### 3. Sensitive Data Exposure
```ruby
# Bad — Logging sensitive data
Rails.logger.info("Password: #{password}")

# Good — Filter sensitive params
Rails.application.config.filter_parameters += [:password, :token, :secret]
```

### 4. XXE
```ruby
# Bad
Nokogiri::XML(user_input)

# Good
Nokogiri::XML(user_input) { |config| config.nonet.noent }
```

### 5. Broken Access Control
```ruby
# Bad — No authorization
@entity = Entity.find(params[:id])

# Good when Authorization: pundit
@entity = Entity.find(params[:id])
authorize @entity

# Good when Authorization: scoped-model
@entity = Current.account.entities.find(params[:id])
```

### 6. Security Misconfiguration
```ruby
# production.rb
config.force_ssl = true
```

### 7. XSS
```erb
<%# Bad %>
<%= raw user_input %>
<%= user_input.html_safe %>

<%# Good %>
<%= user_input %>
<%= sanitize(user_input) %>
```

### 8. Insecure Deserialization
```ruby
# Bad
YAML.load(user_input)

# Good
YAML.safe_load(user_input, permitted_classes: [Symbol, Date])
```

### 9. Vulnerable Dependencies
```bash
bin/bundler-audit check --update
```

### 10. Insufficient Logging
```ruby
Rails.logger.warn("Failed login for #{email} from #{request.remote_ip}")
```

## Security Checklist

### Configuration
- [ ] `config.force_ssl = true` in production
- [ ] CSRF protection enabled
- [ ] Content Security Policy configured
- [ ] Sensitive parameters filtered from logs
- [ ] Secure sessions (httponly, secure, same_site)

### Code
- [ ] Strong Parameters on all controllers
- [ ] Profile-selected authorization enforced on every protected action
- [ ] No `html_safe`/`raw` on user input
- [ ] Parameterized SQL queries only
- [ ] File upload validation

### Dependencies
- [ ] Bundler Audit clean
- [ ] Gems up to date
- [ ] No abandoned gems
