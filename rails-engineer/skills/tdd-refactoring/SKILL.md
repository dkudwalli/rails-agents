---
name: tdd-refactoring
description: >-
  Refactors Rails code under green tests: extracting methods and objects, removing duplication, and reducing complexity without changing behaviour. Use when the user asks to refactor, clean up, or simplify existing code that has test coverage. WHEN NOT: Writing new behaviour, deciding whether an extraction is warranted yet (see extraction-timing), or planning the order of work across a whole legacy codebase, which is `legacy-migration`.
license: MIT
compatibility: Ruby 3.3+, Rails 8.0+
---

# TDD Refactoring

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`patterns.md`](references/patterns.md) | Refactoring catalogue with before and after Rails examples |
| [`output-format.md`](references/output-format.md) | How to report a refactoring pass |

Refactoring a whole existing application rather than one thing? The order to take these in is in
[`layered-legacy-migration`](../layered-legacy-migration/SKILL.md).

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
