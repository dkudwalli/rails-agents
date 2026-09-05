---
name: channel-bay-backend
description: >-
  Guides ChannelBay backend changes involving controllers, models, services, PostgreSQL migrations,
  Devise access, CarrierWave, and merchant-scoped domain behavior. WHEN NOT: the change is primarily
  frontend, asynchronous, integration, operations, testing, or review work.
---

# ChannelBay backend

Read AGENTS.md and 37signals-conventions, then these companion documents, before changing domain
code:

- ~/Projects/cb-dev-docs/docs/architecture/overview.md
- ~/Projects/cb-dev-docs/docs/architecture/core-concepts.md
- ~/Projects/cb-dev-docs/docs/architecture/database-guide.md

- Scope every merchant-owned read and write from current_merchant or the explicit merchant passed to
  a service. Never replace a scoped lookup with a global find.
- Keep controllers thin: authenticate and scope there, then invoke model-owned domain behavior.
  New local CRUD or state behavior belongs on the owning model or a model-namespaced concern, not in
  a new service object.
- When a touched service owns local domain logic, move the current slice incrementally to its model
  while retaining a delegating facade until callers move. Keep services at external provider,
  reporting/query, and compatibility boundaries.
- Preserve ChannelBay's ViewComponent presentation boundary, Devise authentication, CarrierWave
  uploads, PostgreSQL, and Docker workflow. These are platform constraints, not reasons to retain a
  service-heavy domain layer.
- Use PostgreSQL-aware Rails 7.1 migrations. Add tenant-aware indexes for new merchant-owned query
  paths and inspect nearby migrations before choosing constraints or defaults.
- For inventory, channels, mappings, orders, and onboarding behavior, read the relevant domain
  section and ~/Projects/cb-dev-docs/docs/reference/where-to-find-things.md before selecting
  files. Product mappings use
  source_variant_id and mapping configuration; SKU is not a universal identity key.

Run backend commands through Docker Compose web. Use channel-bay-testing for the required proof.
