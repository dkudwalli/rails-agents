---
name: presenter-patterns
description: >-
  Builds presenter objects with SimpleDelegator to move display logic out of models and views. Use when a view needs formatting, derived labels, or conditional display logic, or when the user mentions presenters, decorators, or view models. Applies only in a layered profile app. WHEN NOT: A rich-models profile app — use rich-models-rails-architecture. Reusable markup with its own template, which is a ViewComponent (see viewcomponent-patterns), or domain logic, which belongs in the model.
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Presenter Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`patterns.md`](references/patterns.md) | SimpleDelegator structure, collection presenters, common formatting |
| [`testing.md`](references/testing.md) | RSpec specs for presenters |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
