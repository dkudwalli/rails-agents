---
description: Validate that the codebase implements what the feature spec promises using a 4-layer hybrid analysis — no code annotations required.
handoffs:
  - label: Review Spec
    agent: sdd:spec-review
    prompt: Review the spec for gaps found during validation
  - label: Update Specification
    agent: sdd:specify
    prompt: Update the specification to reflect actual implementation
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/sdd-validate/SKILL.md` in full and execute it.

Everything the user typed after the command is the input that skill asks for.
