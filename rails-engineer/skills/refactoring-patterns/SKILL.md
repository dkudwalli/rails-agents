---
name: refactoring-patterns
description: >-
  Refactors vanilla Rails code toward the 37signals shape: splitting a fat model into namespaced concerns, turning a boolean or timestamp into a state record, renaming a verb endpoint as the noun it creates. Use when the user asks to refactor, clean up, or restructure existing code, or mentions extracting concerns or promoting state to a record. WHEN NOT: Writing new behaviour; adding a service layer, which this profile does not have; or planning the order of work across a whole legacy codebase, which is `rich-models-legacy-migration`.
compatibility: Ruby 3.3+, Rails 8.0+
---

# Refactoring Patterns

Read the file that covers what you are doing rather than all of them.

| Reference | Read it for |
|---|---|
| [`refactoring-patterns.md`](references/refactoring-patterns.md) | The catalogue of refactorings with before and after examples |
| [`migration-strategies.md`](references/migration-strategies.md) | Sequencing a refactor safely across deploys and data |

Refactoring a whole existing application rather than one thing? The order to take these in is in
[`rich-models-legacy-migration`](../rich-models-legacy-migration/SKILL.md).

These references assume the 37signals profile: rich models, namespaced concerns, state records,
Minitest with fixtures, plain CSS, no service layer. Record which source application you are
following before applying them — see the target application's `AGENTS.md` Rails Engineer Profile.
