---
name: mailer-patterns
description: >-
  Writes Action Mailer classes, email templates, previews, and their specs. Use when sending transactional or notification email, building multipart templates, or when the user mentions mailers, email previews, or deliver_later. WHEN NOT: In-app notifications with no email, or background job structure itself (see job-patterns).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# Mailer Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`patterns.md`](references/patterns.md) | Mailer classes, parameterised mailers, delivery |
| [`templates.md`](references/templates.md) | HTML and text email templates |
| [`previews.md`](references/previews.md) | Mailer preview classes |
| [`tests.md`](references/tests.md) | RSpec specs for mailers |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
