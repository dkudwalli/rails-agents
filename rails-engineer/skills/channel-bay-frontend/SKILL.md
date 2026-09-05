---
name: channel-bay-frontend
description: >-
  Guides ChannelBay ViewComponent, ERB, Tailwind v4, Turbo, Stimulus, esbuild, and JavaScript
  changes. WHEN NOT: the request primarily changes backend domain behavior, async processing,
  integrations, operations, testing, or review.
---

# ChannelBay frontend

Read AGENTS.md, ~/Projects/cb-dev-docs/docs/view-components/overview.md, and the matching component
or frontend document before changing UI behavior.

- Reuse app/components primitives and established domain components before adding markup or a new
  component. Keep ERB server-rendered and make accessibility part of the component contract.
- Use Tailwind CSS v4 through the existing CSS build pipeline. Do not introduce a second CSS
  toolchain, importmap, or plain-CSS token system.
- Prefer Turbo Frames and Streams for partial updates. Add Stimulus only for browser behavior that
  Turbo cannot express; register controllers through the canonical controller loader and lazy
  registry.
- Preserve current data attributes, targets, values, and event contracts when changing components
  or controllers. Read nearby JavaScript tests before extending a controller.
- Run JavaScript and CSS commands in their Docker services, never against Docker-owned host assets.

Consult channel-bay-testing for the frontend regression gate and focused JS/component coverage.
