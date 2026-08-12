---
name: rails-guide
description: >-
  Finds the profile-aware Rails Engineer entrypoint for a request. Use after installing Rails
  Engineer when unsure whether an application needs onboarding or which stable rails-* router should
  guide a feature, change, or review. WHEN NOT: a complete profile exists and the user already named
  the specialist skill to use.
user-invocable: true
---

# Rails guidance navigator

Read the target application's `AGENTS.md` and its Rails Engineer Profile before naming detailed
guidance. This skill is a navigator: it selects the first stable router, not a replacement for the
selected router's profile-aware instructions.

## Profile check

If the profile is missing, incomplete, or has malformed `rails-engineer:profile` markers, explain
that conventions have not been recorded yet. Direct the user to `rails-onboard` and stop; do not
guess a profile, edit application files, or begin implementation guidance. `rails-onboard` will
inspect the app, propose an editable profile, and ask for explicit confirmation before it writes.

If the profile is complete, state the recorded architecture and any relevant deliberate divergence,
then select the first router below. For work that spans rows, name one primary router and the
secondary routers in the order they should be consulted.

| Request concerns | Start with |
|---|---|
| Feature planning, a change, implementation sequence, or SDD | `rails-workflow` |
| Code placement, service/query/concern choice, or a new application layer | `rails-architecture` |
| Models, domain behavior, state, or concerns | `rails-models` |
| New, repaired, or organized test coverage | `rails-testing` |
| CSS, tokens, Tailwind, or component styling | `rails-css` |
| Schema, migrations, identifiers, or database review | `rails-database` |
| Authentication, sessions, authorization, or account-scoped access | `rails-access` |
| Jobs, queues, caching, Action Cable, or realtime infrastructure | `rails-runtime` |
| Views, components, Turbo, Stimulus, or frontend assets | `rails-frontend` |
| Accounts, memberships, tenant boundaries, or tenant operations | `rails-tenancy` |
| Deployment, containers, CI, releases, or operations | `rails-deployment` |

When no row is clearly primary, start with `rails-architecture`. Do not route to a layered or
rich-models specialist directly unless the selected stable router directs it there.
