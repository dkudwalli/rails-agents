---
name: rspec-patterns
description: >-
  Writes RSpec specs across every layer — models, requests, services, policies, jobs, mailers, components, and system specs — with FactoryBot. Use when adding or fixing tests, or when the user mentions RSpec, FactoryBot, or spec structure. WHEN NOT: The rails-37signals pack, which uses Minitest and fixtures, or mutation coverage (see mutation-testing).
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# RSpec Patterns

Read [`test-examples.md`](references/test-examples.md) — worked spec examples for every layer,
plus FactoryBot factories.

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
