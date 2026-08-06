---
name: rails-deployment
description: >-
  Routes Rails release, container, CI, and operational setup work to the selected deployment profile.
  Use when editing deployment configuration or release tooling. WHEN NOT: replacing production
  operations solely to match a new-app default.
---

# Rails deployment router

Read AGENTS.md and its Rails Engineer Profile first. Deployment: kamal uses the existing Kamal
configuration and tooling-ci-deploy where it applies. Deployment: docker-procfile uses the
conditional 37signals playbook deployment material. Existing production configuration outranks a
new default unless a deliberate divergence says otherwise.
