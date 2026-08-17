---
name: form-patterns
description: >-
  Builds form objects for multi-model, wizard, and non-ActiveRecord forms using ActiveModel. Use when one form writes to several models, a form needs validation unrelated to persistence, or the user mentions form objects or wizard forms. Applies only in a layered profile app. WHEN NOT: A rich-models profile app — use rich-models-rails-architecture. A plain single-model form, which needs no form object, or business rules that belong in a service.
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Form Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`form-patterns.md`](references/form-patterns.md) | ActiveModel form objects, multi-model saves, wizard steps |
| [`testing-and-views.md`](references/testing-and-views.md) | Form specs and view integration |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
