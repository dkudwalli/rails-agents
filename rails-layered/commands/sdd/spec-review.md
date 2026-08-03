---
description: Adversarial review of the feature spec from security, performance, edge-case, scalability, and regulatory perspectives to catch blind spots before planning.
handoffs:
  - label: Clarify Spec Requirements
    agent: sdd:clarify
    prompt: Clarify specification requirements based on review findings
    send: true
  - label: Update Specification
    agent: sdd:specify
    prompt: Update the feature specification to address review findings
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/sdd-spec-review/SKILL.md` in full and execute it.

Everything the user typed after the command is the input that skill asks for.
