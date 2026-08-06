---
name: rails-access
description: >-
  Routes Rails authorization and authentication work to the profile's recorded mechanisms. Use for
  sign-in flows, sessions, access checks, and account-scoped lookup design. WHEN NOT: installing or
  replacing an identity library without an explicit profile decision.
---

# Rails access router

Read AGENTS.md and its Rails Engineer Profile first. Authorization: pundit selects policy-patterns;
Authorization: scoped-model selects crud-patterns and the 37signals authorization reference.
Authentication: secure-password selects authentication-flow; a session-record choice selects
auth-setup. A mismatch from the architecture default must already be a deliberate divergence; do not
migrate identity or authorization code automatically.
