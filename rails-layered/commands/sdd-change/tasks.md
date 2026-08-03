---
description: Generate a flat task list (3-8 tasks) for a small change based on the change spec.
handoffs:
  - label: Implement Change
    agent: sdd-change:implement
    prompt: Implement the tasks for this change
    send: true
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/sdd-change-tasks/SKILL.md` in full and execute it.

Everything the user typed after the command is the input that skill asks for.
