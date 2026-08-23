---
name: viewcomponent-patterns
description: >-
  Builds tested, reusable UI components with the ViewComponent gem, including previews. Use when markup repeats across views, a UI element needs its own tests, or the user mentions ViewComponent, component previews, or design system components. WHEN NOT: One-off markup (use a partial) or pure formatting of an existing object (see presenter-patterns).
compatibility: Ruby 3.3+, Rails 8.0+
---

# ViewComponent Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`component-examples.md`](references/component-examples.md) | Component structure, slots, variants, collection components |
| [`testing-and-previews.md`](references/testing-and-previews.md) | Component specs and preview classes |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
