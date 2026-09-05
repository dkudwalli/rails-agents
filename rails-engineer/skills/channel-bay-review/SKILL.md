---
name: channel-bay-review
description: >-
  Reviews ChannelBay changes for merchant isolation, Rails 7.1 compatibility, integration safety,
  async correctness, frontend regressions, and missing verification. WHEN NOT: the request is to
  implement or diagnose rather than assess an existing change.
---

# ChannelBay change review

Read AGENTS.md and the relevant companion documents before reviewing. Start with the changed
merchant, channel, job, provider, and UI boundaries rather than applying generic Rails style rules.
Use 37signals-conventions as the default architecture standard for new or modernized domain code.

Prioritize findings that can:

- cross merchant or staff-workspace boundaries, weaken Devise/webhook authentication, or expose
  secrets;
- violate Rails 7.1 or established CarrierWave, ViewComponent, Tailwind, Solid Queue/Cable, or
  Docker constraints;
- add new service objects for local CRUD/state behavior instead of a model method, a
  model-namespaced concern, or a resourceful controller; or miss a safe opportunity to simplify a
  touched service into its domain owner;
- duplicate provider work, lose retry/idempotency state, exceed provider rate limits, or leave sync
  histories/mutations inconsistent;
- bypass product-mapping identity and inventory event semantics;
- break Turbo/Stimulus contracts, frontend accessibility, or existing test and operational evidence.

Use ~/Projects/cb-dev-docs/docs/reference/contributing.md,
~/Projects/cb-dev-docs/docs/reference/testing-guide.md, and
~/Projects/cb-dev-docs/docs/reference/where-to-find-things.md to validate local conventions
and coverage. Report concrete, file-backed findings in severity order;
use the specialist skill to implement an approved fix.
