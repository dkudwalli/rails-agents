---
name: code-review
description: >-
  Analyzes Rails code quality, architecture, and patterns without modifying
  code. Use when the user wants a code review, quality analysis, architecture
  audit, or when user mentions review, audit, code quality, anti-patterns,
  or SOLID principles. WHEN NOT: Actually implementing fixes (use rails-guide),
  writing new tests (use rails-testing), or generating new
  features.
user-invocable: true
argument-hint: "[file or directory path]"
---

# Code Review

## Profile routing

Read the target application's `AGENTS.md` and its Rails Engineer Profile before reviewing. If the
profile is absent, use `rails-onboard` and stop. Keep `code-review` as the public entrypoint, then
select the review vocabulary from the recorded profile:

- `Architecture: layered` — use `layered-conventions` for the review and
  `layered-legacy-migration` to sequence an application-wide remediation.
- `Architecture: rich-models` — use `review-patterns` for the review and
  `rich-models-legacy-migration` to sequence an application-wide remediation. Do not flag the
  absence of service, query, form, presenter, or policy layers as a defect.
- Select test expectations through `rails-testing` and authorization expectations through
  `rails-access`. A recorded deliberate divergence overrides either default.

You NEVER modify code — you only read, analyze, and report findings.

## Review Process

### Step 1: Run Static Analysis

```bash
bin/brakeman        # when present
bin/bundler-audit   # when present
bundle exec rubocop # when configured
```

### Step 2: Analyze Code

Read and evaluate against these focus areas:

1. **Selected Architecture** — violations identified by the profile-selected review guidance
2. **Rails Anti-Patterns** — profile-incompatible placement, N+1 queries, callback hazards
3. **Security** — Mass assignment, SQL injection, XSS, missing authorization
4. **Performance** — Missing indexes, inefficient queries, caching opportunities
5. **Code Quality** — Naming, duplication, method complexity, test coverage

### Step 3: Structured Feedback

Format your review as:

1. **Summary:** High-level overview
2. **Critical Issues (P0):** Security, data loss risks
3. **Major Issues (P1):** Performance, maintainability
4. **Minor Issues (P2-P3):** Style, improvements
5. **Positive Observations:** What was done well

For each issue: **What** → **Where** (file:line) → **Why** → **How** (code example)

Reviewing a whole application rather than a diff? Group the next steps by the selected migration
skill above, so the audit hands off in executable order rather than in severity order. Say which
phases this app can skip.

Read the `behavioral-guidelines` skill § Reporting Rules and apply it on top of this format.
The P0–P3 structure above stays as-is; the reporting rules add what it doesn't cover — omit sections with
no findings, drop recommendations too vague to act on, and the two rules about reviewing tests.

## Anti-Pattern Examples

**Layered profile only — Fat Controller → Service Object:**
```ruby
# Bad
class EntitiesController < ApplicationController
  def create
    @entity = Entity.new(entity_params)
    @entity.calculate_metrics
    @entity.send_notifications
    if @entity.save then ... end
  end
end

# Good
class EntitiesController < ApplicationController
  def create
    result = Entities::CreateService.call(entity_params)
  end
end
```

**N+1 Query → Eager Loading:**
```ruby
# Bad
@entities.each { |e| e.user.name }

# Good
@entities = Entity.includes(:user)
```

**Missing Authorization:**
```ruby
# Bad
@entity = Entity.find(params[:id])

# Good when Authorization: pundit
@entity = Entity.find(params[:id])
authorize @entity

# Good when Authorization: scoped-model
@entity = Current.account.entities.find(params[:id])
```

## Review Checklist

- [ ] Security: Brakeman clean
- [ ] Dependencies: Bundler Audit clean
- [ ] Style: RuboCop compliant
- [ ] Architecture: selected profile conventions respected
- [ ] Patterns: no unapproved mixing of layered and rich-model patterns
- [ ] Performance: No N+1, indexes present
- [ ] Authorization: the `rails-access`-selected mechanism is enforced
- [ ] Tests: the `rails-testing`-selected suite covers affected behavior
- [ ] Naming: Clear, consistent
- [ ] Duplication: No repeated code
