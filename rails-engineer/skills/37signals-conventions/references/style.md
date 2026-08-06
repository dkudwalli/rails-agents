---
paths:
  - "app/**/*.rb"
  - "lib/**/*.rb"
---

# 37signals Ruby Style

**Before writing a new pattern, find the nearest existing example in this codebase and copy its
shape.** Nearly everything you need already exists somewhere. Consistency beats individual judgement.

- **Expanded conditionals over guard clauses.** This is the single biggest stylistic difference from
  mainstream Rails — the source applications average roughly one guard clause per 1,000 lines of
  `app/`. Early return only at the start of a method, when it genuinely improves flow
- `if identity = Identity.find_by(...)` — assignment inside the condition is deliberate, and omakase
  permits it
- Method ordering: class methods → public instance (`initialize` first) → private. Order each section
  by invocation, so vertical order matches read order
- **No newline under `private`/`protected`; indent the body under it.** This requires
  `rubocop-rails-omakase` — stock RuboCop or Standard will fight the entire codebase
- In a module containing only private methods, put `private` first with a blank line after and no
  indentation
- Bang methods (`!`) only when a non-bang counterpart exists — never to flag that something serious
  happens. `Card#close` destroys a record and has no bang
- Let method names describe domain transitions. Do not translate generic controller verbs into hidden
  business logic
- Prefer string enums over integers; use `normalizes` for data cleanup (strip, downcase)
- Default values via lambdas: `default: -> { Current.user }`
- Keyword arguments defaulting to `Current` (`def close(user: Current.user)`) so callers can override
- Comments record *why*, and flag cross-file coupling — not what the code already says
- **No service *layer*.** A plain object is fine when it is the clearest domain object; it lives in
  `app/models/` with a domain name, not in a `services/` directory with a `Service` suffix
- Start from `rubocop-rails-omakase`; add local rules only for an actual team decision

See [`01-philosophy.md`](../../../docs/37signals-playbook/01-philosophy.md) and
[`02-ruby-style.md`](../../../docs/37signals-playbook/02-ruby-style.md).
