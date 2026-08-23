---
name: layered-turbo-patterns
description: >-
  Implements Turbo Drive, Turbo Frames, Turbo Streams, and broadcasts for fast page updates with minimal JavaScript. Use when adding partial page updates, live updates, inline editing, morphing, or prefetch, or when the user mentions Turbo, frames, or streams. Applies only in a layered profile app. WHEN NOT: A rich-models profile app — use rich-models-turbo-patterns. Complex client-side behaviour needing a Stimulus controller (see rails-frontend), API-only JSON endpoints (see api-versioning), or static pages.
compatibility: Ruby 3.3+, Rails 8.0+
---

# Turbo Patterns

Read the reference that covers what you are doing, not all of them.

| Reference | Read it for |
|---|---|
| [`turbo-drive.md`](references/turbo-drive.md) | Drive config, morphing, prefetch, view transitions |
| [`turbo-frames.md`](references/turbo-frames.md) | Frame targeting, lazy loading, inline editing |
| [`turbo-streams.md`](references/turbo-streams.md) | Stream actions, responses, and multi-target updates |
| [`broadcasts.md`](references/broadcasts.md) | Broadcasting model changes over Action Cable |
| [`testing.md`](references/testing.md) | Request and system specs for Turbo responses |

Rules live in `layered-conventions`, layer-boundary decisions in `rails-architecture`; this skill
holds the code. When they disagree, the conventions win.
