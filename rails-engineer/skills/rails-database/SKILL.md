---
name: rails-database
description: >-
  Routes Rails database, identifier, schema, and migration work to the selected adapter and profile.
  Use for schema design, migrations, IDs, and database review. WHEN NOT: changing a production
  database solely because another profile prefers it.
---

# Rails database router

Read AGENTS.md and its Rails Engineer Profile first. Database: postgres selects postgres-patterns;
SQLite or MySQL selects the 37signals conditional playbook database chapters and the app's existing
adapter conventions. Select layered-migration-patterns for a layered profile and
rich-models-migration-patterns for a rich-models profile. Respect the profile's IDs choice and treat
any adapter change as separately approved migration work.
