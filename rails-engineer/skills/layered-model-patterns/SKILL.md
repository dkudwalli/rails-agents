---
name: layered-model-patterns
description: >-
  Worked ActiveRecord model implementations: enums, polymorphic associations, custom validations, scopes, callbacks, delegations, and JSONB, plus model specs and FactoryBot factories. Use when writing or testing a concrete model. WHEN NOT: The model-layer rules themselves (see layered-conventions) or deciding whether a callback should be extracted (see extraction-timing).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Model Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`model-patterns.md`](references/model-patterns.md) | Structure template and eight common model patterns |
| [`testing-and-factories.md`](references/testing-and-factories.md) | Model specs, validation and callback tests, FactoryBot factories |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
