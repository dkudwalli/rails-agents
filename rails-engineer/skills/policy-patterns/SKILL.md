---
name: policy-patterns
description: >-
  Worked Pundit policy implementations: action predicates, scopes, headless policies, and inheritance, plus policy specs and controller wiring. Use when writing or testing a concrete policy. WHEN NOT: The rich-models pack, which authorizes by scoping and ships no policy layer, or the authorization rules themselves (see layered-conventions).
compatibility: Ruby 3.3+, Rails 8.0+
---

# Policy Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`policy-patterns.md`](references/policy-patterns.md) | Policy shapes, scopes, and inheritance |
| [`testing-and-controllers.md`](references/testing-and-controllers.md) | Policy specs and controller integration |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
